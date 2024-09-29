%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

%}

CLASS           [Cc][Ll][Aa][Ss][Ss]
ELSE            [Ee][Ll][Ss][Ee]
FI              [Ff][Ii]
IF              [Ii][Ff]
IN              [Ii][Nn]
INHERITS        [Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
ISVOID          [Ii][Ss][Vv][Oo][Ii][Dd]
LET             [Ll][Ee][Tt]
LOOP            [Ll][Oo][Oo][Pp]
POOL            [Pp][Oo][Oo][Ll]
THEN            [Tt][Hh][Ee][Nn]
WHILE           [Ww][Hh][Ii][Ll][Ee]
CASE            [Cc][Aa][Ss][Ee]
ESAC            [Ee][Ss][Aa][Cc]
NEW             [Nn][Ee][Ww]
OF              [Oo][Ff]
NOT             [Nn][Oo][Tt]
TRUE            t[Rr][Uu][Ee]
FALSE           f[Aa][Ll][Ss][Ee]
INT             [0-9]+
TYPEID					[A-Z][a-zA-Z0-9_]*
OBJECTID				[a-z][a-zA-Z0-9_]*
DARROW          =>
LE							<=
ASSIGN					<-
WHITESPACE			[ \f\r\t\v]+
NEWLINE					\n
SYMBOLS					[+/\-*=<.~,;:()@{}]
INVALID					[^a-zA-Z0-9_ \f\r\t\v\n+/\-*=<.~,;:()@{}]
%x COMMENT
%x INLINE_COMMENT
%x STRING

%%

 /* Operatotr */
{DARROW}		{ return (DARROW); }
{LE}				{ return (LE); }
{ASSIGN}		{ return (ASSIGN); }
{WHITESPACE}	{}
{NEWLINE}		{ curr_lineno++; }
{SYMBOLS} 	{ return int(yytext[0]); }

 /* Keyword */
 /*
  * Keywords are -insensitive except for the values true and false,
  * which must begin with a lower- letter.
  */
{CLASS}			{ return (CLASS); }
{ELSE}			{ return (ELSE); }
{FI}				{ return (FI); }
{IF}				{ return (IF); }
{IN}				{ return (IN); }
{INHERITS}	{ return (INHERITS); }
{ISVOID}		{ return (ISVOID); }
{LET}				{ return (LET); }
{LOOP}			{ return (LOOP); }
{POOL}			{ return (POOL); }
{THEN}			{ return (THEN); }
{WHILE}			{ return (WHILE); }
{CASE}			{ return (CASE); }
{ESAC}			{ return (ESAC); }
{NEW}				{ return (NEW); }
{OF}				{ return (OF); }
{NOT}				{ return (NOT); }
{TRUE} {
	cool_yylval.boolean = true;
	return BOOL_CONST;
}
{FALSE} {
	cool_yylval.boolean = false;
	return BOOL_CONST;
}
{TYPEID} {
	cool_yylval.symbol = idtable.add_string(yytext);
	return (TYPEID);
}
{OBJECTID} {
	cool_yylval.symbol = idtable.add_string(yytext);
	return (OBJECTID);
}

  /* Constant */
  /* Int */
{INT} {
	cool_yylval.symbol = inttable.add_string(yytext);
	return INT_CONST;
}
 /* String */
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  *
  */
\" {
	string_buf_ptr = string_buf;
	BEGIN(STRING);
}
<STRING>\"	{
	BEGIN(INITIAL);
	*string_buf_ptr = '\0';
	cool_yylval.symbol = stringtable.add_string(string_buf);
	return STR_CONST;
}
<STRING>\n {
	curr_lineno++;
	BEGIN(INITIAL);
	cool_yylval.error_msg = "Unterminated string constant";
	return ERROR;
}
<STRING>\0 {
	BEGIN(INITIAL);
	cool_yylval.error_msg = "String contains null character";
	return ERROR;
}
<STRING><<EOF>> {
	BEGIN(INITIAL);
	cool_yylval.error_msg = "EOF in string constant";
	return ERROR;
}
<STRING>\\n  {
	if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST-1]) {
		BEGIN(INITIAL);
		cool_yylval.error_msg = "String constant too long";
		return ERROR;
	}
	*string_buf_ptr++ = '\n';
}
<STRING>\\t  {
	if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST-1]) {
		BEGIN(INITIAL);
		cool_yylval.error_msg = "String constant too long";
		return ERROR;
	}
	*string_buf_ptr++ = '\t';
}
<STRING>\\b  {
	if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST-1]) {
		BEGIN(INITIAL);
		cool_yylval.error_msg = "String constant too long";
		return ERROR;
	}
	*string_buf_ptr++ = '\b';
}
<STRING>\\f  {
	if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST-1]) {
		BEGIN(INITIAL);
		cool_yylval.error_msg = "String constant too long";
		return ERROR;
	}
	*string_buf_ptr++ = '\f';
}
<STRING>\\(.|\n)	{
	if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST-1]) {
		BEGIN(INITIAL);
		cool_yylval.error_msg = "String constant too long";
		return ERROR;
	}
	*string_buf_ptr++ = yytext[1];
}
<STRING>[^\\\n\"]+ {
	char *yptr = yytext;
	while ( *yptr ) {
		if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST-1]) {
			BEGIN(INITIAL);
			cool_yylval.error_msg = "String constant too long";
			return ERROR;
		}
		*string_buf_ptr++ = *yptr++;
	}
}
{INVALID} {
	cool_yylval.error_msg = yytext;
	return ERROR;
}
%%
