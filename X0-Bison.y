%{
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <string.h>

#define bool 			int
#define true 			1
#define false 			0

#define SYM_TABLE 		200				// Max Capicity of symbol table
#define ID_NAME_LEN		20				// Max length of ident
#define ADDRESS_MAX		8192			// Upper bound of the address
#define DEPTH_MAX		10				// Max depth of declaration
#define CODE_MAX		1000			// Max Virtual Machine code amount
#define STACK_SIZE		2000			// Max Run-Time stack element amount
#define STRING_LEN		201				// Max length of const string
#define ERROR_MAG_NUM	1145141919810	// For error processing


typedef unsigned char byte;

enum object {
	constant_int,
	constant_real,
	constant_bool,
	constant_string,
	constant_char,
	variable_int,
	variable_real,
	variable_bool,
	variable_string,
	variable_char,
};

struct symbol_table {
	char 	name[ID_NAME_LEN];
	enum 	object kind;
	int 	addr;
	byte 	val[STRING_LEN];			// Use byte to store all kind of data, use pointer to specify them
	int		init_or_not;
//	void*	val;						// Using pointer to specify unlimitted length constant string @todo: in the future.
};

struct symbol_table table[SYM_TABLE];	// Store all symbol

enum fct {
	lit,	opr,	lod,
	sto,	cal,	ini,
	jmp,	jpc,
};

struct instruction {
	enum 	fct f;
	int 	lev;						// Un-used in X0
	int		opr;
};

struct instruction code[CODE_MAX];		// Store V-Machine code

int			sym_tab_tail;
int			vm_code_pointer;
char		id_name[ID_NAME_LEN];
int			outter_int;
float		outter_real;
bool		outter_bool;
char		outter_char;
char		outter_string[STRING_LEN];
int			err_num;
int			constant_decl_or_not = 0;
int 		var_decl_with_init_or_not = 0;
int			cur_decl_type = -1;

FILE*		fin;
FILE*		ftable;
FILE*		fcode;
FILE*		foutput;
FILE*		fresult;
char		fname;
int 		err;
extern int	line;

void 		init();
void		enter(enum object k);
void 		gen(enum fct x, int y, int z);

%}

%union {
	char 	*ident;
	int 	number;
	char 	*text;
	char 	single_char;
	int 	flag;
	double 	realnumber;
}

%token BOOLSYM, BREAKSYM, CALLSYM, CASESYM, CHARSYM, CONSTSYM, CONTINUESYM, DOSYM, ELSESYM
%token ELSESYM, EXITSYM, FORSYM, INTSYM, IFSYM, MAINSYM, READSYM, REALSYM, REPEATSYM
%token STRINGSYM, SWITCHSYM, UNTILSYM, WHILESYM, WRITESYM, LBRACE, RBRACE, LBRACKET, RBRACKET
%token BECOMES, COMMA, LSS, LEQ, GTR, GEQ, EQL, NEQ, PLUS, INCPLUS, MINUS, INCMINUS,TIMES, DEVIDE
%token LPAREN, RPAREN, MOD, SEMICOLON, XOR, AND, OR, NOT, YAJU, YARIMASUNESYM, KIBONOHANASYM

%token <ident> 			IDENT
%token <number> 		INTEGER
%token <text>			STRING
%token <single_char>	CHAR
%token <flag>			BOOL
%token <realnumber>		REAL

%type <number>			factor			// Indicate type of factor
%type <number>			expression		// Indicate type of expression
%type <number>			identlist, identarraylist, identdef
%%

program: 				MAINSYM 
						{	gen(jmp, 0, 0);
						}
						LBRACE 
						statement_list 
						{
						
						}
						RBRACE 
						;
		
declaration_list:		declaration_list declaration_stat 
					  | declaration_stat 
					  | 
						;

declaration_stat:		typeenum identlist SEMICOLON { /* Why can't me add sth after typeenum?? */ }
					  | typeenum identarraylist SEMICOLON
					  | CONSTSYM typeenum { constant_decl_or_not = 1; } identlist { constant_decl_or_not = 0; } SEMICOLON
						;

identlist:				identdef 
					  |	identlist COMMA identdef
					  	;

identdef:				IDENT {
							if (constant_decl_or_not == 1) {		// Constant without initialize, error
								yyerror("Constants require initialization!\n");
								return 1;
							} 
							else {
								var_decl_with_init_or_not = 0;
								strcpy(id_name, $1);
								switch (cur_decl_type) {
									case 2:
										enter(variable_int);
										break;
									case 3:
										enter(variable_real);
										break;
									case 4:
										enter(variable_string);
										break;
									case 5:
										enter(variable_bool);
										break;
									case 6:
										enter(variable_char);
										break;
								}
							}
	 					}
					  |	IDENT BECOMES factor {
						  	if (constant_decl_or_not == 1) {		// Constant declaration
								strcpy(id_name, $1);
								switch (cur_decl_type) {
									case 2:
										enter(constant_int);
										break;
									case 3:
										enter(constant_real);
										break;
									case 4:
										enter(constant_string);
										break;
									case 5:
										enter(constant_bool);
										break;
									case 6:
										enter(constant_char);
										break;
								}
							}
							else {									// Variable declaration, pre-init required?
								var_decl_with_init_or_not = 1;
								strcpy(id_name, $1);
								switch (cur_decl_type) {
									case 2:
										enter(variable_int);
										break;
									case 3:
										enter(variable_real);
										break;
									case 4:
										enter(variable_string);
										break;
									case 5:
										enter(variable_bool);
										break;
									case 6:
										enter(variable_char);
										break;
								}
								var_decl_with_init_or_not = 0;
							}
					  	}
						;

typeenum:				INTSYM 		{ cur_decl_type = 2; }
					  | STRINGSYM 	{ cur_decl_type = 4; }
					  | BOOLSYM 	{ cur_decl_type = 5; }
					  | REALSYM 	{ cur_decl_type = 3; }
					  | CHARSYM		{ cur_decl_type = 6; }
						;

identarraylist:			identarraydef
					  |	identarraylist COMMA identarraydef
						;
				
identarraydef:			IDENT LBRACKET INTEGER RBRACKET
						;
	
statement_list:			statement_list statement 
					  | statement 
					  | 
						;
						
statement:				expression_statement 
					  | if_statement 
					  | while_statement 
					  | read_statement 
					  | write_statement 
					  | compound_statement 
					  | for_statement 
					  | do_statement 
					  | declaration_list
					  | continue_stat 
					  | break_stat 
					  |
						;
						
continue_stat:			CONTINUESYM SEMICOLON
						;
						
break_stat:				BREAKSYM SEMICOLON
						;
						
if_statement:			IFSYM LPAREN expression RPAREN compound_statement 
					  | IFSYM LPAREN expression RPAREN compound_statement ELSESYM compound_statement 
						;
	
while_statement:		WHILESYM LPAREN expression RPAREN compound_statement
						;
	
write_statement:		WRITESYM LPAREN expression RPAREN SEMICOLON
						;
	
read_statement:			READSYM LPAREN var RPAREN SEMICOLON
						;
						
compound_statement:		LBRACE statement_list RBRACE
						;
						
for_statement:			FORSYM LPAREN expression SEMICOLON expression SEMICOLON expression RPAREN compound_statement
						;
						
do_statement:			DOSYM compound_statement WHILESYM LPAREN expression RPAREN SEMICOLON
						;
	
var:					IDENT 
					  | IDENT LBRACKET expression RBRACKET
						;

expression_statement:	expression SEMICOLON 
					  | SEMICOLON
						;

expression:				var BECOMES expression 
						{	gen(lod, 0, 0);
							gen(sto, 0, 0);
							$$ = 0;
						}
					  | simple_expr
						;

simple_expr:			additive_expr 
					  | additive_expr OPR additive_expr 
					  | additive_expr SINGLEOPR 
					  | SINGLEOPR additive_expr
						;

SINGLEOPR:				INCPLUS 
					  | INCMINUS 
					  | NOT
						;

OPR:					EQL 
					  | NEQ 
					  | LSS 
					  | LEQ 
					  | GTR 
					  | GEQ 
					  | AND 
					  | OR 
					  | XOR
						;

additive_expr:			term 
					  | additive_expr PLUSMINUS term
						;

PLUSMINUS:				PLUS 
					  | MINUS
						;

term:					factor 
					  | term TIMESDEVIDE factor
						;

TIMESDEVIDE:			TIMES 
					  | DEVIDE
						;

factor:					LPAREN expression RPAREN {
							$$ = 0;
						}
					  | var {
						  	$$ = 1;
					  	}
					  | INTEGER {
						  	$$ = 2;
							outter_int = $1;
					  	}
					  | REAL {
						  	$$ = 3;
							outter_real = $1;
					  	}
					  | STRING {
						  	$$ = 4;
							strcpy(outter_string, $1);
					  	}
					  | BOOL {
						  	$$ = 5;
							outter_bool = $1;
					  	}
					  | CHAR {
						  	$$ = 6;
							outter_char = $1;
					  	}
					  | YAJU {
						  	$$ = 7;
					  	}
						;

%%

void init() {
	sym_tab_tail 		= 0;
	vm_code_pointer 	= 0 ;
	outter_int 			= 0;
	outter_real 		= 0.0;
	outter_char 		= 0;
	outter_bool 		= false;
	err_num				= 0;
	strcpy(outter_string, "\0");
}

int yyerror(char *s) {
	err_num++;
	printf("%s in line %d.\n", s, line);
	fprintf(foutput, "%s in line %d.\n", s, line);
	return 0;
}

void gen(enum fct x, int y, int z) {
	if (vm_code_pointer > CODE_MAX) {
		printf("Program is too long!\n");
		exit(1);
	}
	if (z > ADDRESS_MAX) {
		printf("Acquiring address out of bound\n");
		exit(1);
	}
	code[vm_code_pointer].f 	= x;
	code[vm_code_pointer].lev 	= y;
	code[vm_code_pointer].opr 	= z;
	vm_code_pointer++;
}

void enter(enum object k) {
	sym_tab_tail++;
	strcpy(table[sym_tab_tail].name, id_name);
	table[sym_tab_tail].kind = k;
	table[sym_tab_tail].init_or_not = 0;
	switch (k) {
		case constant_int:
			memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_int, STRING_LEN);
			break;
		case constant_real:
			memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_real, STRING_LEN);
			break;
		case constant_string:
			memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_string, STRING_LEN);
			break;
		case constant_char:
			memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_char, STRING_LEN);
			break;
		case constant_bool:
			memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_bool, STRING_LEN);
			break;
		case variable_int:
			if (var_decl_with_init_or_not) {
				memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_int, STRING_LEN);
				table[sym_tab_tail].init_or_not = 1;
			}
			break;
		case variable_real:
			if (var_decl_with_init_or_not) {
				memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_int, STRING_LEN);
				table[sym_tab_tail].init_or_not = 1;
			}
			break;
		case variable_string:
			if (var_decl_with_init_or_not) {
				memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_string, STRING_LEN);
				table[sym_tab_tail].init_or_not = 1;
			}
			break;
		case variable_char:
			if (var_decl_with_init_or_not) {
				memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_char, STRING_LEN);
				table[sym_tab_tail].init_or_not = 1;
			}
			break;
		case variable_bool:
			if (var_decl_with_init_or_not) {
				memcpy((void*)&table[sym_tab_tail].val, (const void*)&outter_bool, STRING_LEN);
				table[sym_tab_tail].init_or_not = 1;
			}
			break;
	}
}

void display_sym_tab() {			// @todo: Finish sym-table displaying
	int i;
	for (i = 1; i <= sym_tab_tail; i++) {
		switch (table[i].kind) {
			case constant_int:
				printf("%10d\tconstant\tinteger\t%20s:\t", i, table[i].name);
				printf("value = %d\n", *((int*)&table[i].val));
				fprintf(ftable, "%10d\tconstant\tinteger\t%20s:\t", i, table[i].name);
				fprintf(ftable, "value = %d\n", *((int*)&table[i].val));
				break;
			case constant_real:
				printf("%10d\tconstant\treal\t%20s:\t", i, table[i].name);
				printf("value = %f\n", *((float*)&table[i].val));
				fprintf(ftable, "%10d\tconstant\treal\t%20s:\t", i, table[i].name);
				fprintf(ftable, "value = %f\n", *((float*)&table[i].val));
				break;
			case constant_char:
				printf("%10d\tconstant\tchar\t%20s:\t", i, table[i].name);
				printf("value = %c\n", *((char*)&table[i].val));
				fprintf(ftable, "%10d\tconstant\tchar\t%20s:\t", i, table[i].name);
				fprintf(ftable, "value = %c\n", *((char*)&table[i].val));
				break;
			case constant_string:
				printf("%10d\tconstant\tstring\t%20s:\t", i, table[i].name);
				printf("value = %s\n", table[i].val);
				fprintf(ftable, "%10d\tconstant\tstring\t%20s:\t", i, table[i].name);
				fprintf(ftable, "value = %s\n", table[i].val);
				break;
			case constant_bool:
				printf("%10d\tconstant\tbool\t%20s:\t", i, table[i].name);
				printf("value = %s\n", (*((int*)&table[i].val) == 0) ? "false" : "true");
				fprintf(ftable, "%10d\tconstant\tbool\t%20s:\t", i, table[i].name);
				fprintf(ftable, "value = %s\n", (*((int*)&table[i].val) == 0) ? "false" : "true");
				break;
			case variable_int:
				printf("%10d\tvariable\tinteger\t%20s:\t", i, table[i].name);
				printf("Initialized or not = %d\n", table[i].init_or_not);
				fprintf(ftable, "%10d\tvariable\tinteger\t%20s:\t", i, table[i].name);
				fprintf(ftable, "Initialized or not = %d\n", table[i].init_or_not);
				break;
			case variable_real:
				printf("%10d\tvariable\treal\t%20s:\t", i, table[i].name);
				printf("Initialized or not = %d\n", table[i].init_or_not);
				fprintf(ftable, "%10d\tvariable\treal\t%20s:\t", i, table[i].name);
				fprintf(ftable, "Initialized or not = %d\n", table[i].init_or_not);
				break;
			case variable_char:
				printf("%10d\tvariable\tcahr\t%20s:\t", i, table[i].name);
				printf("Initialized or not = %d\n", table[i].init_or_not);
				fprintf(ftable, "%10d\tvariable\tchar\t%20s:\t", i, table[i].name);
				fprintf(ftable, "Initialized or not = %d\n", table[i].init_or_not);
				break;
			case variable_string:
				printf("%10d\tvariable\tstring\t%20s:\t", i, table[i].name);
				printf("Initialized or not = %d\n", table[i].init_or_not);
				fprintf(ftable, "%10d\tvariable\tstring\t%20s:\t", i, table[i].name);
				fprintf(ftable, "Initialized or not = %d\n", table[i].init_or_not);
				break;
			case variable_bool:
				printf("%10d\tvariable\tbool\t%20s:\t", i, table[i].name);
				printf("Initialized or not = %d\n", table[i].init_or_not);
				fprintf(ftable, "%10d\tvariable\tbool\t%20s:\t", i, table[i].name);
				fprintf(ftable, "Initialized or not = %d\n", table[i].init_or_not);
				break;
		}
	}
}

void interpret() {
	int pc = 0;
	int base = 1;
	int stack_top = 0;
	struct instruction i;
	int s[STACK_SIZE];

	printf("Start X0\n");
	printf(fresult, "Start X0\n");
	s[0] = 0;
	s[1] = s[2] = s[3] = 0; 		//RA, DL, SL of main is 0, though X0 doesn't include recursive decl
	do {
		i = code[pc];
		pc = pc + 1;
		switch (i.fct) {
			case lit:
				stack_top++;
				s[stack_top] = i.opr;
				break;
			case opr:
				switch (i.opr) {
					case 0:
						stack_top = base - 1;
						pc = s[stack_top + 3];
						base = s[stack_top + 2];
						break;
					case 1:								// Negative
						s[stack_top] = -s[stack_top];
						break;
					case 2:								// 2 opr +
						stack_top--;
						s[stack_top] = s[stack_top] + s[stack_top + 1];
						break;
					case 3:								// 2 opr -
						stack_top--;
						s[stack_top] = s[stack_top] - s[stack_top + 1];
						break;
					case 4:								// 2 opr *
						stack_top--;
						s[stack_top] = s[stack_top] * s[stack_top + 1];
						break;
					case 5:								// 2 opr /
						stack_top--;
						s[stack_top] = s[stack_top] / s[stack_top + 1];
						break;
					case 6:								// 2 opr %
						stack_top--;
						s[stack_top] = s[stack_top] % s[stack_top + 1];
						break;
					case 7:								// 2 opr ==
						stack_top--;
						s[stack_top] = (s[stack_top] == s[stack_top + 1]);
						break;
					case 8:								// 2 opr !=
						stack_top--;
						s[stack_top] = (s[stack_top] != s[stack_top + 1]);
						break;
					case 9:								// 2 opr <
						stack_top--;
						s[stack_top] = (s[stack_top] < s[stack_top + 1]);
						break;
					case 10:							// 2 opr >
						stack_top--;
						s[stack_top] = (s[stack_top] > s[stack_top + 1]);
						break;
					case 11:							// 2 opr <=
						stack_top--;
						s[stack_top] = (s[stack_top] <= s[stack_top + 1]);
						break;
					case 12:							// 2 opr >=
						stack_top--;
						s[stack_top] = (s[stack_top] >= s[stack_top + 1]);
						break;
					case 13:
						stack_top--;
						s[stack_top] = (s[stack_top] && s[stack_top + 1]);
						break;
					case 14:
						stack_top--;
						s[stack_top] = (s[stack_top] || s[stack_top + 1]);
						break;
					case 15:
						stack_top--;
						s[stack_top] = (s[stack_top] ^ s[stack_top + 1]);
						break;
					case 16:
						s[stack_top] = !s[stack_top];
						break;
				}
		}
	}
}

void listall() {
	int i;
	char name[][5] = {
		{"lit"}, {"opr"}, {"lod"}, {"sto"},
		{"cal"}, {"ini"}, {"jmp"}, {"jpc"},
	};
	for (i = 0; i < vm_code_pointer; i++) {
		printf("%4d %s %4d %4d\n", i, name[code[i].f], code[i].lev, code[i].opr);
		fprintf(fcode, "%4d %s %4d %4d\n", i, name[code[i].f], code[i].lev, code[i].opr);
	}
}

int main(int argc, int **argv) {
	fcode = fopen("fcode", "w+");
	ftable = fopen("ftable", "w+");
	fresult = fopen("fresult", "w+");
	if (argc != 2) {
		printf("Please specific ONE source code file!\n");
		return 0;
	}
	FILE *f = fopen(argv[1], "r");
	if (!f) {
		perror(argv[1]);
		return 1;
	}
	redirectInput(f);
	init();
	yyparse();
	listall();
	display_sym_tab();
}
