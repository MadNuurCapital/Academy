/**
 * Card now lives on the glass Panel.
 *
 * This file stays as a re-export so the thirty-odd screens already importing
 * `@/components/ui/Card` keep working and inherit the console surface without
 * being touched.
 */
export { Card, CardHeader, CardTitle, CardBody, Panel, Well } from './Panel';
