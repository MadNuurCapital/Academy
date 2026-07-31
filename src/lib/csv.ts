/**
 * CSV export.
 *
 * Every report offers CSV. Written by hand rather than pulled in as a
 * dependency because the requirement is small and the escaping rules are
 * short — but they do need to be correct, since advisor names and remarks
 * routinely contain commas, quotes and apostrophes.
 */

/**
 * Escapes one field per RFC 4180: wrap in quotes when the value contains a
 * comma, a quote or a newline, and double any embedded quotes.
 *
 * A leading =, +, - or @ is prefixed with an apostrophe. Spreadsheet software
 * treats such a value as a formula, so a remark beginning "=" would execute on
 * open — a well-known way to turn an innocuous export into an attack on whoever
 * opens it.
 */
function escapeField(value: unknown): string {
  if (value === null || value === undefined) return '';

  let text = String(value);

  if (/^[=+\-@\t\r]/.test(text)) {
    text = `'${text}`;
  }

  if (/[",\n\r]/.test(text)) {
    return `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}

export function toCsv(headers: string[], rows: unknown[][]): string {
  const lines = [headers.map(escapeField).join(',')];
  for (const row of rows) {
    lines.push(row.map(escapeField).join(','));
  }
  // CRLF, which is what RFC 4180 specifies and what Excel expects.
  return lines.join('\r\n');
}

/** Triggers a browser download of the given CSV content. */
export function downloadCsv(filename: string, csv: string): void {
  // U+FEFF. The byte-order mark makes Excel read the file as UTF-8 rather than
  // the local codepage, which otherwise mangles any non-ASCII name. Written as
  // an escape rather than a literal character so it is visible to a reader.
  const blob = new Blob([`\uFEFF${csv}`], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename.endsWith('.csv') ? filename : `${filename}.csv`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
