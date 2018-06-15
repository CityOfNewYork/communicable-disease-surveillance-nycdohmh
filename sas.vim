" Vim syntax file
" Language: SAS
" Maintainer: Zhenhuan Hu <wildkeny@gmail.com>
" Version: 1.2.5
" Last Change:
"
"    30 Mar 2015 by Zhenhuan Hu
"
"    Additional keywords
"
"    19 Jun 2014 by Zhenhuan Hu
"
"    Improved macro comment syntax
"
"    24 Jul 2013 by Zhenhuan Hu
"
"    Minor cosmetic modifications for hash objects
"    Minor bug fixes for statment syntax
"
"    28 Mar 2012 by Zhenhuan Hu
"    
"    Added syntax for macro comment
"
"    27 Feb 2012 by Zhenhuan Hu 
"
"    Completely rewrote approach for highlighting SAS statements 
"    Updated new statements in Base SAS 9.3 and SAS/Stat
"    Fixed glitches in highlighting procedure names and internal variables.
"    Simplify the approach for highlighting SAS functions
"    Added highlighting for hash and hiter objects
"
"    1 Apr 2011 by Zhenhuan Hu
"
"    Fixed mis-recognization of keywords and function names
"    Fixed syntax issues when multiple comment statements being put in the same line
"    More efficient approaches for highlighting statements, procs, and macros
"    Added highlighting for new statements and functions introduced in SAS 9.1/9.2
"    Added highlighting for user defined macro functions, ods statements and formats
"
"    18 Jul 2008 by Paulo Tanimoto <ptanimoto@gmail.com>
"
"    Fixed comments with * taking multiple lines
"    Fixed highlighting of macro keywords
"    Added words to cases that didn't fit anywhere
"
"    02 Jun 2003 by Bob Heckel
"
"    Added highlighting for additional keywords and such
"    Attempted to match SAS default syntax colors
"    Changed syncing so it doesn't lose colors on large blocks
"
"    26 Sep 2001 by James Kidd
"
"    Added keywords for use in SAS SQL procedure and highlighting for
"    SAS base procedures, added logic to distinqush between versions
"    for SAS macro variable highlighting (Thanks to user Ronald
"    Höllwarth for pointing out bug)
"
"    For SAS 5: Clear all syntax items
"    For SAS 6: Quit when a syntax file was already loaded

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" SAS is case insensitive
syn case ignore

syn region sasString start=+"+ skip=+\\\\\|\\"+ end=+"+
syn region sasString start=+'+ skip=+\\\\\|\\"+ end=+'+

" Want region from 'CARDS' to ';' to be captured (Bob Heckel)
syn region sasCards start="\(^\|;\)\s*\(CARDS\|DATALINES\)\>"hs=s+1 end=";" 

syn match sasNumber "-\=\<\d*\.\=[0-9_]\>"

" Block comment
syn region sasComment start="/\*" end="\*/" contains=sasTodo
" Previous code for comments was written by Bob Heckel
" Several comments can be put in the same line (Zhenhuan Hu)
syn region sasComment start="^\s*\*" skip=";\s*\*" end=";"me=e-1 contains=sasTodo
" Comments with * starting after a semicolon (Paulo Tanimoto)
syn region sasComment start=";\s*\*"ms=s+1 end=";"me=e-1 contains=sasTodo
" Macro comments (Zhenhuan Hu)
syn region sasComment start="^\s*%\*" skip=";\s*%\*" end=";"me=e-1 contains=sasTodo
" Macro comments with * starting after a semicolon (Zhenhuan Hu)
syn region sasComment start=";\s*%\*"ms=s+1 end=";"me=e-1 contains=sasTodo
" Self-defined section mark
syn region sasSection start="/\* SECTION" end="\*/" contains=sasTodo

" Base SAS Procs - version 8.1
syn keyword sasStep RUN DATA
syn keyword sasCondition DO ELSE END IF THEN TO OVER UNTIL WHILE 
syn keyword sasOperator AND OR IN NOT EQ NE GT LT GE LE

syn match sasStatementKwd "[^;]" contained

" Data step statments, 9.4 (Zhenhuan Hu)
syn match sasStatement "\(^\|;\)\s*\(ABORT\|ARRAY\|ATTRIB\|BY\|CARDS\|CARDS4\|CATNAME\)\>" contains=sasStatementKwd
syn match sasStatement "\(^\|;\)\s*\(CONTINUE\|DATALINES\|DATALINES4\|DELETE\|DESCRIBE\|DISPLAY\|DM\)\>" contains=sasStatementKwd
syn match sasStatement "\(^\|;\)\s*\(DROP\|ENDSAS\|ERROR\|EXECUTE\|FILE\|FILENAME\|FOOTNOTE\d\=\|FORMAT\)\>" contains=sasStatementKwd
syn match sasStatement "\(^\|;\)\s*\(GOTO\|INFILE\|INFORMAT\|INPUT\|KEEP\|LABEL\|LEAVE\|LENGTH\|LIBNAME\)\>" contains=sasStatementKwd
syn match sasStatement "\(^\|;\)\s*\(LINK\|LIST\|LOCK\|LOSTCARD\|MERGE\|MISSING\|MODIFY\|OPTIONS\|OTHERWISE\|OUTPUT\)\>" contains=sasStatementKwd
syn match sasStatement "\(^\|;\)\s*\(PAGE\|PUT\|PUTLOG\|REDIRECT\|REMOVE\|RENAME\|REPLACE\|RESETLINE\)\>" contains=sasStatementKwd
syn match sasStatement "\(^\|;\)\s*\(RETAIN\|RETURN\|SASFILE\|SELECT\|SET\|SKIP\|STARTSAS\|STOP\)\>" contains=sasStatementKwd
syn match sasStatement "\(^\|;\)\s*\(TITLE\d\=\|UPDATE\|WAITFOR\|WHEN\|WHERE\|WINDOW\|X\)\>" contains=sasStatementKwd
syn match sasStatement "\(^\|;\)\s*DECLARE\s\+\(HASH\|HITER\)\>" contains=sasStatementKwd

" Base SAS 9.4, procedures (Zhenhuan Hu)
syn match sasStatement "\(^\|;\)\s*\(REPAIR\)\>" contains=sasStatementKwd " Proc AUTHLIB
syn match sasStatement "\(^\|;\)\s*\(CALID\|DUR\|FIN\|HOLIDUR\|HOLIFIN\|HOLIVAR\|OUTDUR\|OUTFIN\|OUTSTART\|START\)\>" contains=sasStatementKwd " Proc CALENDAR
syn match sasStatement "\(^\|;\)\s*\(CHANGE\|CONTENTS\|EXCHANGE\|SAVE\)\>" contains=sasStatementKwd " Proc CATALOG
syn match sasStatement "\(^\|;\)\s*\(BLOCK\|HBAR\|PIE\|STAR\|VBAR\)\>" contains=sasStatementKwd " Proc CHART
syn match sasStatement "\(^\|;\)\s*\(TRANTAB\)\>" contains=sasStatementKwd " Proc CPORT
syn match sasStatement "\(^\|;\)\s*\(DBENCODING\|DELIMITER\|FMTLIB\|META\|PUTNAMES\)\>" contains=sasStatementKwd " Proc EXPORT
syn match sasStatement "\(^\|;\)\s*\(DELETEFUNC\|DELETESUBR\|FUNCTION\|LISTFUNC\|LISTSUBR\|OUTARGS\|STRUCT\|SUBROUTINE\)\>" contains=sasStatementKwd " Proc FCMP
syn match sasStatement "\(^\|;\)\s*\(FONTFILE\|FONTPATH\|TRUETYPE\|TYPE1\|OPENTYPE\)\>" contains=sasStatementKwd " Proc FONTREG
syn match sasStatement "\(^\|;\)\s*\(EXCLUDE\|INVALUE\|PICTURE\|SELECT\|VALUE\)\>" contains=sasStatementKwd " Proc FORMAT
syn match sasStatement "\(^\|;\)\s*\(CLASS\|FREQ\|OUTPUT\|TYPES\|WAYS\)\>" contains=sasStatementKwd " Proc MEANS
syn match sasStatement "\(^\|;\)\s*\(BY\|ID\|PAGEBY\|SUM\|SUMBY\|VAR\)\>" contains=sasStatementKwd " Proc PRINT
syn match sasStatement "\(^\|;\)\s*\(RANKS\)\>" contains=sasStatementKwd " Proc RANKS
syn match sasStatement "\(^\|;\)\s*\(BREAK\|COLUMN\|DEFINE\|COMPUTE\|ENDCOMP\|RBREAK\)\>" contains=sasStatementKwd " Proc REPORT
syn match sasStatement "\(^\|;\)\s*\(CLASSLEV\|KEYLABEL\)\>" contains=sasStatementKwd " Proc TABULATE
syn match sasStatement "\(^\|;\)\s*\(COPY\|IDLABEL\)\>" contains=sasStatementKwd " Proc TRANSPOSE
" Base SAS 9.4, statistical procedures
syn match sasStatement "\(^\|;\)\s*\(PARTIAL\|WEIGHT\|WITH\)\>" contains=sasStatementKwd " Proc CORR
syn match sasStatement "\(^\|;\)\s*\(EXACT\|TABLES\=\|TEST\)\>" contains=sasStatementKwd " Proc FREQ
syn match sasStatement "\(^\|;\)\s*\(CDFPLOT\|HISTOGRAM\|INSET\|PPPLOT\|PROBPLOT\|QQPLOT\)\>" contains=sasStatementKwd " Proc UNIVARIATE
" SAS/ODS, 9.4
syn match sasStatement "\(^\|;\)\s*\(BAND\|BUBBLE\|DENSITY\|DOT\|ELLIPSE\|HBARPARM\|HBOX\|HIGHLOW\|HLINE\)\>" contains=sasStatementKwd " Proc SGPLOT
syn match sasStatement "\(^\|;\)\s*\(PANELBY\|COLAXIS\|ROWAXIS\)\>" contains=sasStatementKwd " Proc SGPANEL
syn match sasStatement "\(^\|;\)\s*\(COMPARE\|MATRIX\|PLOT\)\>" contains=sasStatementKwd " Proc SGSCATTER
syn match sasStatement "\(^\|;\)\s*\(DYNAMIC\)\>" contains=sasStatementKwd " Proc SGDESIGN, SGRENDER
syn match sasStatement "\(^\|;\)\s*\(INSET\|KEYLEGEND\|LINEPARM\|LOESS\|NEEDLE\|PBSPLINE\|REFLINE\|REG\|SCATTER\)\>" contains=sasStatementKwd 
syn match sasStatement "\(^\|;\)\s*\(SERIES\|STEP\|VBARPARM\|VBOX\|VECTOR\|VLINE\|WATERFALL\|XAXIS\|X2AXIS\|YAXIS\|Y2AXIS\)\>" contains=sasStatementKwd 

" SAS/GRAPH, version 9.3 (Zhenhuan Hu)
syn match sasStatement "\(^\|;\)\s*\(AXIS\d\{0,2}\|GOPTIONS\|LEGEND\d\{0,2}\|NOTE\|PATTERN\d\{0,3}\|SYMBOL\d\{0,3}\)\>" contains=sasStatementKwd 
syn match sasStatement "\(^\|;\)\s*\(HBAR3D\|PIE3D\|VBAR3D\)\>" contains=sasStatementKwd " Proc GCHART
syn match sasStatement "\(^\|;\)\s*\(BUBBLE2\|PLOT2\=\)\>" contains=sasStatementKwd " Proc GPLOT

" SAS/STAT statments, version 9.3 (Zhenhuan Hu)
syn match sasStatement "\(^\|;\)\s*\(BASELINE\|MODEL\)\>" contains=sasStatementKwd " Proc PHREG

" Proc SQL keywords (Zhenhuan Hu)
syn keyword sasProcSQLKwd ADD AND ALTER AS BY CASCADE CHECK CREATE contained
syn keyword sasProcSQLKwd DELETE DESCRIBE DISTINCT DROP FOREIGN contained
syn keyword sasProcSQLKwd FROM FULL GROUP HAVING INDEX INSERT INTO IN INNER contained
syn keyword sasProcSQLKwd JOIN KEY LEFT LIKE MESSAGE MODIFY MSGTYPE NOT contained
syn keyword sasProcSQLKwd ON ORDER OUTER QUIT RESET RESTRICT RIGHT SELECT SET contained
syn keyword sasProcSQLKwd TABLE TABLES UNIQUE UPDATE VALIDATE VIEW WHERE contained

" ODS keywords (Zhenhuan Hu)
syn keyword sasODSKwd ODS CLOSE CHTML CSVALL contained
syn keyword sasODSKwd DOCBOOK DOCUMENT ESCAPECHAR EXCLUDE contained
syn keyword sasODSKwd GRAPHICS HTML HTMLCSS HTML3 IMODE LISTING contained
syn keyword sasODSKwd MAKEUP OFF ON OUTPUT PACKAGES PATH PCL PDF PHTML contained
syn keyword sasODSKwd PRINTER PROCLABEL PROCTITLE PS RESULTWS RTF contained
syn keyword sasODSKwd SELECT SHOW TAGSET TEXT TRACE USEGOPT VERIFY WML contained
syn match sasStatement "\(^\|;\)\s*\(STYLE\)\>" contains=sasStatementKwd " Proc TEMPLATE

syn region sasODS start="\(^\|;\)\s*\ODS\>" end=";"me=e-1 contains=sasODSKwd, sasString, sasNumber, sasComment, sasMacro, sasMacroFunction, sasMacroVar

" SAS formats
syn match sasFormatValue "\w\+\." contained
syn region sasFormat start="\(^\|;\)\s*\(FORMAT\|INPUT\)\>" end=";"me=e-1 contains=sasFormatValue, sasStatement, sasString, sasNumber, sasStep, sasComment, sasMacro, sasMacroFunction, sasMacroVar

" No need to specify PROC list if use this line (Bob Heckel).
" Match options contained in the PROC statement (Zhenhuan Hu);
syn match sasProcName "\<PROC\( \w\+\>\|\>\)" contained
syn region sasProc start="^\s*PROC" end=";"me=e-1 contains=sasProcName, sasStep, sasString, sasNumber, sasComment, sasMacro, sasMacroFunction, sasMacroVar
syn region sasProcSQL start="^\s*PROC SQL\>" end="\(^\|;\)\s*quit\s*;"me=e-1 contains=sasProcName, sasStep, sasString, sasNumber, sasComment, sasMacro, sasMacroFunction, sasMacroVar, sasProcSQLKwd keepend

" Thanks to Ronald Höllwarth for this fix to an intra-versioning
" problem with this little feature
" Used a more efficient way to match macro vars (Zhenhuan Hu)
if version < 600
  syn match sasMacroVar "\&\+\w\+"
else
  syn match sasMacroVar "&\+\w\+"
endif

" Match declarations have to appear one per line (Paulo Tanimoto)
" No need for declaring each macro function, only macro statements are included (Zhenhuan Hu)
syn match sasMacro "%\(ABORT\|MACRO\|COPY\|DISPLAY\|DO\|TO\|BY\|UNTIL\|WHILE\|END\)\>"
syn match sasMacro "%\(GLOBAL\|GOTO\|IF\|ELSE\|THEN\|INPUT\|LABEL\|LET\|LOCAL\|MEND\)\>"
syn match sasMacro "%\(PUT\|RETURN\|SYMDEL\|SYSCALL\|SYSEXEC\|SYSLPUT\|SYSRPUT\|WINDOW\|INCLUDE\)\>"

" User defined macro functions (Zhenhuan Hu)
syn match sasMacroFunction "%\w\+("he=e-1

" SAS functions and call routines (Zhenhuan Hu)
syn match sasFunction "\<\(CALL\s\+\|\w\+\.\|\)\w\+("he=e-1

" Always contained in a comment (Bob Heckel)
syn keyword sasTodo TODO TBD FIXME contained

" These don't fit anywhere else (Bob Heckel).
" Added others that were missing (Zhenhuan Hu).
syn match sasInternalVariable "\<\(_ALL_\|_AUTOMATIC_\|_CHARACTER_\|_INFILE_\|_N_\|_NAME_\|_NULL_\|_NUMERIC_\|_USER_\|_WEBOUT_\)\>"

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet

if version >= 508 || !exists("did_sas_syntax_inits")
  if version < 508
    let did_sas_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  " hi Procedure term=bold ctermfg=Green gui=bold guifg=Orange
  " hi Section gui=none guifg=grey20 guibg=White

  HiLink sasComment Comment
  HiLink sasCondition Statement
  HiLink sasOperator Statement 
  HiLink sasStep Statement
  HiLink sasStatementKwd Statement
  HiLink sasProcSQLKwd Statement
  HiLink sasODSKwd Statement
  HiLink sasFunction Function
  HiLink sasMacro Macro
  HiLink sasMacroFunction Macro
  HiLink sasMacroVar Macro
  HiLink sasNumber Number
  HiLink sasFormatValue Tag
  HiLink sasString String
  HiLink sasProcName Keyword 
  HiLink sasSection Underlined
  HiLink sasTodo Todo
  HiLink sasCards Special
  HiLink sasInternalVariable Define
  
  delcommand HiLink
endif

" Syncronize from beginning to keep large blocks from losing
" syntax coloring while moving through code.
syn sync fromstart

let b:current_syntax = "sas"

" vim: ts=8
