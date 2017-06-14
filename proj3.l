%{
	#include <iostream>
	#include <string>
	#include <queue>
	#include <map>
	#include <list>
	#include "y.tab.h"
 
	#define LIST strcat(buf,yytext)
	#define MAX_LINE_LENG 256

	#define UNSURE_TYPE 0
	#define INT_TYPE 1
	#define REAL_TYPE 2
	#define STRING_TYPE 3
	#define BOOL_TYPE 4
	#define VOID_TYPE 5

	#define UNSURE_STYLE 0
	#define FUNC_STYLE 1
	#define ARRAY_STYLE 2
	#define VAR_STYLE 3
	#define CONST_STYLE 4
	// queue<string> handler;

	typedef union YYSTYPE infor;
	bool flagNonsingle=false;
	bool flagSingle=false;
	int linenum = 1;
	char buf[MAX_LINE_LENG];
	std::string strbuf;
	
	class idtuple{
	public:
		idtuple(){
			name = "0";
			value = "0";
			scope = "0";
			type = 0;
			style = 0;
			size = -1;
		}
		idtuple(std::string myname, std::string myscope, std::string myvalue, int mytype, int mystyle, int mysize){
			name = myname;
			value = myvalue;
			scope = myscope;
			type = mytype;
			style = mystyle;
			size = mysize;
		}
		std::string getname(){return name;}
		std::string getvalue(){return value;}
		std::string getscope(){return scope;}
		int gettype(){return type;}
		int getstyle(){return style;}
		int getsize(){return size;}
		void setname(std::string s){name=s;}
	private:
		std::string name;
		std::string value;
		std::string scope;
		int type;
		int style;
		int size;
		int count;
	};
	class hashtable;
	std::list<hashtable> symbolTables;
	class hashtable{
		public:
			hashtable(){
				count=0;
			}
			int lookup(std::string s){
				std::map<std::string,idtuple>::iterator it;
				it = idTables.find(s);
				if(it != idTables.end()){
					return 1;
				}else{
					return -1;
				}
			}
			int insert(std::string s, idtuple id){
				idTables[s]=id;
				intTables[count]=id;
				count++;
				return count-1;
			}
			idtuple getdata(std::string s){
				idtuple id;
				std::map<std::string,idtuple>::iterator it;
				it = idTables.find(s);
				id = it->second;
				return id;
			}
			void dump(){
				printf("id value type style size\n");
				printf("type 0:UNSURE_TYPE 1:INT_TYPE 2:REAL_TYPE 3:STRING_TYPE 4:BOOL_TYPE 5:VOID_TYPE\n");
				printf("style 0:UNSURE_STYLE 1:FUNC_STYLE 2:ARRAY_STYLE 3:VAR_STYLE 4:CONST_STYLE\n");
				for (std::map<int,idtuple>::iterator it=intTables.begin(); it!=intTables.end(); ++it){
    				std::cout << it->first << " => " << it->second.getname()<<" "<< it->second.getvalue() <<" "<< it->second.gettype() <<" "<< it->second.getstyle()<<" "<< it->second.getsize() << '\n';
				}
			}
			int get_idnumber(std::string s){
				int temp=-1,flag=0;
				std::list<hashtable>::iterator it;
					for (it=symbolTables.begin(); it!=symbolTables.end(); ++it)
					{
						if(it->lookup(s) == 1 && flag == 0){
							// printf("aaaaaa %s\n", s.c_str());
							if(it==std::prev(symbolTables.end())) return -1;
							for (int j = 0; j < it->count; ++j){
								if(it->intTables[j].getname() == s){
							// printf("aaaaaa %s\n", s.c_str());
									temp = j;
									flag = 1;
									break;
								}
							}
						}else{
							if(it==std::prev(symbolTables.end())){
								//printf("sdddddddddddddddddddd\n");
								break;
							}
							temp += it->count; 
						}
					}
					// printf("%s temp : %d\n",s.c_str(), temp);
					return temp;
			}
		private:
			std::map<std::string,idtuple> idTables;
			std::map<int,idtuple> intTables;
			int count;
	};
	
	
	void create(){
    	hashtable temp;
		symbolTables.push_front(temp);
	}

	// void handleString(){
	// 	string tmp;
	// 	if (!handler.empty()){
	// 		while(!handler.empty()){
	// 			tmp.append(handler.front());
	// 			tmp.erase(tmp.size()-1);
	// 			handler.pop();
	// 		}
	// 		tmp.append("\"");
	// 		cout<<"<string:"<<tmp<<">"<<endl;
	// 	}
	// }

	int token(int def){
		LIST; 
		if(flagNonsingle==false&&flagSingle==false){
			// handleString();
			// printf("<%s>\n",yytext);
		}
		return def;
	}

	int tokenKeyword(int def){
		LIST;
		if(flagNonsingle==false&&flagSingle==false){
			// handleString();
			// printf("<keyword:%s>\n",yytext);
		}
		return def;
	}

	int tokenIdentifiers(int def){
		LIST;
		if(flagNonsingle==false&&flagSingle==false){
			// handleString();
			// printf("<id:%s>\n",yytext);
			/*if (symbolTables.front().lookup(yytext)==-1){
				idtuple id;
				id.setname(yytext);
				symbolTables.front().insert(yytext,id);
				// printf("aaaaaaaaaaaaaaaaaaaaa %s\n", id.getname().c_str());
				// printf("hereeeeeeeeeeeeeeeeeeeeeeeeeeeee %d\n", symbolTables.front().lookup(yytext));
			}*/
			return def;
		}
	} 
	
	// void tokenString(){
	// 	LIST;
	// 	if(flagNonsingle==false&&flagSingle==false){
	// 		handler.push(yytext);
	// 	}
	// }

%}
%x strings
%x comment

comma ,
colon :
semicolon ;
left_parentheses \(
right_parentheses \)
left_squarebrackets \[
right_squarebrackets \]
left_brackets \{
right_brackets \}
arithmetic_addition \+
arithmetic_subtraction \-
arithmetic_multiplication \*
arithmetic_divide \/
exponentiation \^
remainder %
relational_less <
relational_lessEqual <=
relational_greaterEqual >=
relational_greater >
relational_equal ==
relational_notEqual !=
logical_and &
logical_or "|"
logical_not !
assignment =
compoundOperators_addAssign \+\=
compoundOperators_subAssign \-\=
compoundOperators_mulAssign \*\=
compoundOperators_divAssign \/\=
letters [a-zA-Z]
digits [0-9]+
identifiers {letters}({letters}|{digits})*
integerConstants {digits}*
booleanConstants_true true
booleanConstants_false false
decimal {integerConstants}\.{integerConstants}
exponent {decimal}(e|E)(\+|\-)?{integerConstants}
realConstants {decimal}|{exponent}

%%
{comma} {return token( COMMA);}
{colon} {return token( COLON);}
{semicolon} {return token( SEMICOLON);}
{left_parentheses} {return token( LEFT_PARENTHESES);}
{right_parentheses} {return token( RIGHT_PARENTHESES);}
{left_squarebrackets} {return token( LEFT_SQUAREBRACKETS);}
{right_squarebrackets} {return token( RIGHT_SQUAREBRACKETS);}
{left_brackets} {return token( LEFT_BRACKETS);}
{right_brackets} {return token( RIGHT_BRACKETS);}
{arithmetic_addition} {return token( ARITHMETIC_ADDITION);}
{arithmetic_subtraction} {return token( ARITHMETIC_SUBTRACTION);}
{arithmetic_multiplication} {return token( ARITHMETIC_MULTIPLICATION);}
{arithmetic_divide} {return token( ARITHMETIC_DIVIDE);}
{exponentiation} {return token( EXPONENTIATION);}
{remainder} {return token( REMAINDER);}
{relational_less} {return token( RELATIONAL_LESS);}
{relational_lessEqual} {return token( RELATIONAL_LESSEQUAL);}
{relational_greaterEqual} {return token( RELATIONAL_GREATEREQUAL);}
{relational_greater} {return token( RELATIONAL_GREATER);}
{relational_equal} {return token( RELATIONAL_EQUAL);}
{relational_notEqual} {return token( RELATIONAL_NOTEQUAL);}
{logical_and} {return token( LOGICAL_AND);}
{logical_or} {return token( LOGICAL_OR);}
{logical_not} {return token( LOGICAL_NOT);}
{assignment} {return token( ASSIGNMENT);}
{compoundOperators_addAssign} {return token( COMPOUNDOPERATORS_ADDASSIGN);}
{compoundOperators_subAssign} {return token( COMPOUNDOPERATORS_SUBASSIGN);}
{compoundOperators_mulAssign} {return token( COMPOUNDOPERATORS_MULASSIGN);}
{compoundOperators_divAssign} {return token( COMPOUNDOPERATORS_DIVASSIGN);}

{booleanConstants_true} %{
	infor::info its_T;
	its_T.name = new std::string("const");
	its_T.value = new std::string("1");;
	its_T.type = BOOL_TYPE;
	its_T.style = CONST_STYLE;
	its_T.size = -1;
	yylval.myinfo=its_T;
	return token( BOOLEANCONSTANTS_TRUE);%}
{booleanConstants_false} %{
	infor::info its_F;
	its_F.name = new std::string("const");
	its_F.value = new std::string("0");;
	its_F.type = BOOL_TYPE;
	its_F.style = CONST_STYLE;
	its_F.size = -1;
	yylval.myinfo=its_F;
	return token( BOOLEANCONSTANTS_FALSE);%}

"bool" {return tokenKeyword( BOOL);}
"break" {return tokenKeyword( BREAK);}
"case" {return tokenKeyword( CASE);}
"const" {return tokenKeyword( CONST);}
"continue" {return tokenKeyword( CONTINUE);}
"default" {return tokenKeyword( DEFAULT);}
"else" {return tokenKeyword( ELSE);}
"false" {return tokenKeyword( FALSE);}
"for" {return tokenKeyword( FOR);}
"func" {return tokenKeyword( FUNC);}
"go" {return tokenKeyword( GO);}
"if" {return tokenKeyword( IF);}
"import" {return tokenKeyword( IMPORT);}
"int" {return tokenKeyword( INT);}
"nil" {return tokenKeyword( NIL);}
"print" {return tokenKeyword( PRINT);}
"println" {return tokenKeyword( PRINTLN);}
"real" {return tokenKeyword( REAL);}
"return" {return tokenKeyword( RETURN);}
"string" {return tokenKeyword( STRING);}
"struct" {return tokenKeyword( STRUCT);}
"switch" {return tokenKeyword( SWITCH);}
"true" {return tokenKeyword( TRUE);}
"type" {return tokenKeyword( TYPE);}
"var" {return tokenKeyword( VAR);}
"void" {return tokenKeyword( VOID);}
"while" {return tokenKeyword( WHILE);}
"read" {return tokenKeyword( READ);}
{identifiers} %{
	infor::info its_ID;
	its_ID.name = new std::string(yytext);
	its_ID.value = new std::string("0");
	its_ID.type = UNSURE_TYPE;
	its_ID.style = UNSURE_STYLE;
	its_ID.size = -1;
	yylval.myinfo=its_ID;
	return tokenIdentifiers( IDENTIFIERS);%}
{integerConstants} %{
	infor::info its_INT;
	its_INT.name = new std::string("const");
	its_INT.value = new std::string(yytext);
	its_INT.type = INT_TYPE;
	its_INT.style = CONST_STYLE;
	its_INT.size = -1;
	yylval.myinfo=its_INT;
	return token( INTEGERCONSTANTS);%}
{realConstants} %{
	infor::info its_REAL;
	its_REAL.name = new std::string("const");
	its_REAL.value = new std::string(yytext);
	its_REAL.type = REAL_TYPE;
	its_REAL.style = CONST_STYLE;
	its_REAL.size = -1;
	yylval.myinfo=its_REAL;
	return token( REALCONSTANTS);%}

\"			{
				BEGIN strings;
				strbuf = "";
				LIST;
			}
<strings>\" 	{
				BEGIN 0;
				// printf("<string:%s>\n", strbuf.c_str());
				infor::info its_STRING;
				its_STRING.name = new std::string("const");
				its_STRING.value = new std::string(strbuf.c_str());
				its_STRING.type = STRING_TYPE;
				its_STRING.style = CONST_STYLE;
				its_STRING.size = -1;
				yylval.myinfo=its_STRING;
				return STRINGCONSTANTS;
			}
<strings>\"\" {
				strbuf+="\"";
				LIST;
			}

<strings>\n 	{
				printf("missing terminal symbol \"\n");
				exit(-1);
			}
<strings>.	{
				strbuf+=yytext;
				LIST;
			}
\/\*		{
				BEGIN comment;
			}
<comment>\n {
				// printf("%d: %s\n", linenum++, buf);
			}
<comment>\*\/ {
				BEGIN 0;
			}
<comment>.	{}
\/\/.*\n {/*printf("%d:%s\n", linenum++, buf);*/ buf[0]='\0';}

[ \t]* {LIST;}
\n {
	flagSingle = false;
	LIST;
	// printf("%d: %s", linenum++, buf);
	buf[0] = '\0';
}
. {
	LIST;
	if(flagNonsingle==false&&flagSingle==false){
		// printf("%d:%s\n", linenum++, buf);
		printf("bad character:'%s'\n",yytext);
		exit(-1);
	}

}
%%
// int main(){
// 	hashtable one;
// 	one = create();
// 	yylex();
// 	one = symbolTables.front();
// 	one.dump();
// }