import { describe, expect, it } from 'vitest';
import { toCsv } from './csv';

describe('toCsv', () => {
  it('writes a header row and data rows separated by CRLF', () => {
    expect(toCsv(['Name', 'Status'], [['Alice Tan', 'Present']])).toBe(
      'Name,Status\r\nAlice Tan,Present',
    );
  });

  it('quotes fields containing a comma', () => {
    expect(toCsv(['Remark'], [['Late, traffic on the PIE']])).toBe(
      'Remark\r\n"Late, traffic on the PIE"',
    );
  });

  it('doubles embedded quotes', () => {
    expect(toCsv(['Remark'], [['He said "on my way"']])).toBe(
      'Remark\r\n"He said ""on my way"""',
    );
  });

  it('quotes fields containing a newline', () => {
    expect(toCsv(['Note'], [['First line\nSecond line']])).toBe(
      'Note\r\n"First line\nSecond line"',
    );
  });

  it('renders null and undefined as empty rather than the word "null"', () => {
    expect(toCsv(['A', 'B'], [[null, undefined]])).toBe('A,B\r\n,');
  });

  it('neutralises values a spreadsheet would execute as a formula', () => {
    // Without the leading apostrophe, opening this export in Excel would run
    // the formula rather than display the text.
    expect(toCsv(['Remark'], [['=1+1']])).toBe("Remark\r\n'=1+1");
    expect(toCsv(['Remark'], [['+44 9123']])).toBe("Remark\r\n'+44 9123");
    expect(toCsv(['Remark'], [['-5 days']])).toBe("Remark\r\n'-5 days");
    expect(toCsv(['Remark'], [['@user']])).toBe("Remark\r\n'@user");
  });

  it('quotes a formula-like value that also contains a comma', () => {
    expect(toCsv(['Remark'], [['=SUM(A1,A2)']])).toBe(`Remark\r\n"'=SUM(A1,A2)"`);
  });

  it('handles an empty row set', () => {
    expect(toCsv(['Name'], [])).toBe('Name');
  });

  it('preserves numbers and booleans as plain text', () => {
    expect(toCsv(['Score', 'Passed'], [[80, true]])).toBe('Score,Passed\r\n80,true');
  });
});
