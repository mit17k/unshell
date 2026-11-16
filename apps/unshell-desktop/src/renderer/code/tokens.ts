/** One coloured run of text within a line. Offsets are UTF-16 columns. */
export interface CodeToken {
  content: string;
  column: number;
  color?: string | undefined;
  italic?: boolean | undefined;
  bold?: boolean | undefined;
  underline?: boolean | undefined;
  /** Set when an LSP semantic token overrode the grammar colour. */
  semanticType?: string | undefined;
}

export type CodeLine = CodeToken[];
