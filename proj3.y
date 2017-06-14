%{
    #include "lex.yy.c"
    #include <stdio.h>
    #define Trace(t) printf(t)
    void yyerror(char *msg);
    using namespace std;

    void dump();

    int L_count=0;
    string classname;
    std::string typesname[6] = {"unsure","int","int","string","int","void"};
    std::string nowscope;
    list<std::string> scope;
    std::map<std::string, list<int>*> func_arg;/*存型態 因為.l都宣告成數字了所以是int*/
    
    void insert(std::string s, idtuple id){
        symbolTables.begin()->insert(s,id);
    }
    // 執行的時候 提取值用的 要看全部的人有宣告過的東西
    int lookup(std::string s){
        for (std::list<hashtable>::iterator it=symbolTables.begin(); it!=symbolTables.end(); ++it){
            if(it->lookup(s)==1)
                return 1;
        }
        return -1;
    }   
    // 宣告用只看自己的scope
    int current_lookup(std::string s){
        if(symbolTables.front().lookup(s)==1)
            return 1;
        else
            return -1;
    }
    void init_scope(){
        create();
        nowscope = "golbal";
        scope.push_front("golbal");
    }
    void start_scope(std::string s){
        create();
        nowscope = s;
        scope.push_front(s);
    }
    void end_scope(){
        symbolTables.pop_front();
        scope.pop_front();
        nowscope = scope.front();
    }
    // 從hashtable裡面拿資料出來
    infor::info getdata(std::string s){
        infor::info in;
        idtuple id;
        for (std::list<hashtable>::iterator it=symbolTables.begin(); it!=symbolTables.end(); ++it){
            if(it->lookup(s)==1){
                id = it->getdata(s);
                in.name = new std::string(id.getname());
                in.value = new std::string(id.getvalue());
                in.type = id.gettype();
                in.style = id.getstyle();
                in.size = id.getsize();
                return in; 
            }
        }
        in.name = new std::string("0");
        in.value = new std::string("0");
        in.type = 0;
        in.style = 0;
        in.size = -1;
        return in;

    }
    void dump(){
        for (std::list<hashtable>::iterator it=symbolTables.begin(); it!=symbolTables.end(); ++it){
            it->dump();
            // std::cout << it->first << " => " << it->second.getname() << '\n';
        }
    }
    void dump_arglist(){
        std::list<int>* temp = new std::list<int>;
        for (std::map<string,list<int>*>::iterator it=func_arg.begin(); it!=func_arg.end(); ++it){
            temp = func_arg[it->first];
            cout<<it->first<<" =>";
            for(std::list<int>::iterator it=temp->begin(); it!=temp->end(); ++it){
                cout<<' '<<*it;
            }
            cout<<endl;
        }
    }

%}
%union {
    int val;
    // id的資訊 名字 值 類型 型態 空間大小 func要傳入參數的型態有哪些
    struct info
    {
        std::string* name;
        std::string* value;
        int style;
        int type;
        int size;
    }myinfo;
    std::list<int>* argstype;
}
/* tokens */
%token BOOL BREAK CASE CONST CONTINUE DEFAULT ELSE FALSE FOR FUNC GO IF IMPORT INT NIL PRINT PRINTLN REAL RETURN STRING STRUCT SWITCH TRUE TYPE VAR VOID WHILE READ
%token COMMA COLON SEMICOLON LEFT_PARENTHESES RIGHT_PARENTHESES LEFT_SQUAREBRACKETS RIGHT_SQUAREBRACKETS LEFT_BRACKETS RIGHT_BRACKETS
%token ARITHMETIC_ADDITION ARITHMETIC_SUBTRACTION ARITHMETIC_MULTIPLICATION ARITHMETIC_DIVIDE
%token EXPONENTIATION REMAINDER
%token RELATIONAL_LESS RELATIONAL_LESSEQUAL RELATIONAL_GREATEREQUAL RELATIONAL_GREATER RELATIONAL_EQUAL RELATIONAL_NOTEQUAL
%token LOGICAL_AND LOGICAL_OR LOGICAL_NOT ASSIGNMENT
%token COMPOUNDOPERATORS_ADDASSIGN COMPOUNDOPERATORS_SUBASSIGN COMPOUNDOPERATORS_MULASSIGN COMPOUNDOPERATORS_DIVASSIGN

%token<myinfo> IDENTIFIERS BOOLEANCONSTANTS_TRUE BOOLEANCONSTANTS_FALSE REALCONSTANTS INTEGERCONSTANTS STRINGCONSTANTS

%left ARITHMETIC_ADDITION ARITHMETIC_SUBTRACTION
%left ARITHMETIC_MULTIPLICATION ARITHMETIC_DIVIDE REMAINDER
%left EXPONENTIATION
%nonassoc POSITIVE
%nonassoc NEGATIVE

%type<argstype> formal_arguments
%type<val> type formal_argument 
%type<myinfo> exp number int_exp bool_exp num_exp func_exp array_exp constant variable constant_exp declaration simple

%%
start:              programs{
                    printf("\n");
                    // Trace("Reducing to start\n");
                }
                ;
programs:           program programs
                |   
                {
                    // Trace("Reducing to programs\n");
                }
                ;
program:            functions
                |   contents{
                    // Trace("Reducing to program\n");
                }
                ;
functions:          function functions
                |   
                {
                    // Trace("Reducing to functions\n");
                }
                ;
function:           FUNC type IDENTIFIERS LEFT_PARENTHESES{
                        if (current_lookup($3.name->c_str())==-1){
                            idtuple temp($3.name->c_str(), nowscope, "0", $2, FUNC_STYLE, 1);
                            insert($3.name->c_str(),temp);
                        }else{
                            printf("func redefine\n");
                            return 1;
                        }
                        start_scope("function");
                        if (string($3.name->c_str())=="main")
                        {
                            printf("method public static %s main(java.lang.String[])\n", typesname[$2].c_str());
                        }else{
                            printf("method public static %s %s", typesname[$2].c_str(), $3.name->c_str());
                        }
                    } 
                    formal_arguments{
                        if (string($3.name->c_str())!="main"){
                            printf("(");
                            for (std::list<int>::iterator it = $6->begin(); it!=$6->end() ;++it)
                            {
                                if (it==std::prev($6->end()))
                                    printf("%s", typesname[*it].c_str());
                                else
                                    printf("%s,", typesname[*it].c_str());
                            }
                            printf(")\n");
                        }
                        printf("max_stack 15\nmax_locals 15\n{\n");
                            
                    } 
                    RIGHT_PARENTHESES LEFT_BRACKETS contents RIGHT_BRACKETS{
                        func_arg[$3.name->c_str()] = $6;
                        // function 要被宣告時利用current_lookup function 去看這個id在當前scope裡是否已經被宣告過了
                        
                        // Trace("Reducing to function\n");
                        end_scope();
                        printf("}\n");
                    }  
                ;

type:               BOOL{
                    $$=BOOL_TYPE;
                    // Trace("Reducing to type\n");
                }
                |   INT{
                    $$=INT_TYPE;
                    // Trace("Reducing to type\n");
                }
                |   REAL{
                    $$=REAL_TYPE;
                    // Trace("Reducing to type\n");
                }
                |   STRING{
                    $$=STRING_TYPE;
                    // Trace("Reducing to type\n");
                }
                |   VOID{
                    $$=VOID_TYPE;
                    // Trace("Reducing to type\n");
                }
                ;

formal_arguments:   formal_argument COMMA formal_arguments{
                    $3->push_front($1);
                    $$=$3;
                }
                |   formal_argument{
                    std::list<int>* temp = new std::list<int>;
                    $$ = temp;
                    $$->push_front($1);
                }
                |
                {
                    std::list<int>* temp = new std::list<int>;
                    $$ = temp;
                    // Trace("Reducing to formal_arguments\n");
                }
                ;

formal_argument:    IDENTIFIERS type{
                    if (current_lookup($1.name->c_str()) == 1){
                        printf("%s redefine\n", $1.name->c_str());
                        return 1;
                    }else{
                        $$=$2;
                        idtuple temp($1.name->c_str(), nowscope, "0", $2, VAR_STYLE, -1);
                        insert($1.name->c_str(),temp);
                    }
                    // Trace("Reducing to formal_argument\n");
                }
                ;

exp:                num_exp{
                    $$=$1;
                    // Trace("Reducing to exp\n");
                }
                |   bool_exp{
                    $$=$1;
                    // Trace("Reducing to exp\n");
                }
                |   array_exp{
                    $$=$1;
                    // Trace("Reducing to exp\n");   
                }
                |   func_exp{
                    $$=$1;
                    // Trace("Reducing to exp\n");   
                }
                |   STRINGCONSTANTS{
                    $$=$1;
                    printf("ldc \"%s\"\n", $1.value->c_str());
                    // Trace("Reducing to exp\n");
                }
                ;

contents:           content contents
                |   
                {
                    // Trace("Reducing to contents\n");
                }
                ;
content:            declaration
                |   statement
                |   function{
                    // Trace("Reducing to content\n");
                }
                ;

/*statements:         statement statements
                |
                {
                    Trace("Reducing to statements\n");
                }
                ;*/
statement:          simple
                |   compound
                |   conditional
                |   loop
                |   procedure_invocation
                |   // 6/6 for's empty statement
                {
                    // Trace("Reducing to statement\n");
                }
                ;

simple:             IDENTIFIERS ASSIGNMENT exp{
                    // 判斷id是否存在 再判斷id是不是const 再判斷type是否相同
                    if(lookup($1.name->c_str())==1){
                        $1 = getdata($1.name->c_str()); 
                        if($1.style==CONST_STYLE){
                            printf("const can not be assign\n");
                            return 1;
                        }
                        if ($1.type!=$3.type){
                            printf("%s %d = %s %d\n",$1.name->c_str(), $1.type, $3.name->c_str() ,$3.type);
                            printf("type is not equal\n");
                            return 1;
                        }
                        $$ = getdata($3.name->c_str());
                        if(symbolTables.front().get_idnumber($$.name->c_str())!=-1)
                            printf("istore %d\n", symbolTables.front().get_idnumber($1.name->c_str()));
                        else if(symbolTables.front().get_idnumber($$.name->c_str())==-1)
                            printf("putstatic int %s.%s\n", classname.c_str(), $1.name->c_str());
                    }else{
                        printf("id doesn't exist\n");
                        return 1;
                    }
                    // Trace("Reducing to simple\n");
                }
                |   IDENTIFIERS LEFT_SQUAREBRACKETS int_exp RIGHT_SQUAREBRACKETS ASSIGNMENT exp{
                    // 判斷array id是否存在 再判斷type是否相同
                    if(lookup($1.name->c_str())==1){
                        $1 = getdata($1.name->c_str());
                        if ($1.type!=$6.type){
                            printf("type is not equal\n");
                            return 1;
                        }
                        //id is array, index over range or not
                        if(atoi($3.value->c_str())>=$1.size)
                        {
                            printf("ID is not array or index over range\n");
                            return 1;
                        }

                        $$ = getdata($6.name->c_str()); 
                    }else{
                        printf("id doesn't exist\n");
                        return 1;
                    }
                    // Trace("Reducing to simple\n");
                }
                |   PRINT{printf("getstatic java.io.PrintStream java.lang.System.out\n");} exp{
                    if ($3.type==3)
                        printf("invokevirtual void java.io.PrintStream.print(java.lang.String)\n");
                    else
                        printf("invokevirtual void java.io.PrintStream.print(int)\n");
                    // Trace("Reducing to simple\n");
                }
                |   PRINTLN{printf("getstatic java.io.PrintStream java.lang.System.out\n");} exp{
                    if ($3.type==3)
                        printf("invokevirtual void java.io.PrintStream.println(java.lang.String)\n");
                    else
                        printf("invokevirtual void java.io.PrintStream.println(int)\n");
                    // Trace("Reducing to simple\n");
                }
                |   READ IDENTIFIERS{
                    // Trace("Reducing to simple\n");
                }
                |   RETURN{
                    printf("return\n");
                    // Trace("Reducing to simple\n");
                }
                |   RETURN exp{
                    printf("ireturn\n");
                    // Trace("Reducing to simple\n");
                }
                ;
                // 遇到大括號 就開新的scope
compound:           LEFT_BRACKETS{start_scope("compound");} contents RIGHT_BRACKETS
                {
                    // 大括號結束 關閉
                    end_scope();
                    // Trace("Reducing to compound\n");
                }
                ;

conditional:        IF LEFT_PARENTHESES bool_exp RIGHT_PARENTHESES{
                    printf("ifeq Lfalse_%d\n", L_count);
                }    
                    compound{
                    printf("goto Lexit_%d\n", L_count);
                    printf("Lfalse_%d:\n", L_count);
                }   ELSE compound{
                    printf("Lexit_%d:\n", L_count++);
                    printf("nop\n");
                    // Trace("Reducing to conditional\n");
                }
                // |   IF LEFT_PARENTHESES bool_exp RIGHT_PARENTHESES compound
                // {
                //     // Trace("Reducing to conditional\n");
                // }
                ;
                    // 這邊值注意一下 再我的設定之上 分號一定要
loop:               FOR LEFT_PARENTHESES statement {
                    printf("Ltest_%d:\n", L_count);
                }
                    SEMICOLON bool_exp{
                    printf("ifeq Lexit_%d\n", L_count-1);
                    printf("goto Lbody_%d\n", L_count-1);
                    printf("Lpost_%d:\n", L_count-1);
                }
                    SEMICOLON statement{
                    printf("goto Ltest_%d\n", L_count-1);
                    printf("Lbody_%d:\n", L_count-1);
                }
                    RIGHT_PARENTHESES compound{
                    printf("goto Lpost_%d\n", L_count-1);
                    printf("Lexit_%d:\n", L_count-1);
                    L_count++;
                    // Trace("Reducing to loop\n");
                }
                ;
procedure_invocation:
                    GO func_exp
                {
                    // Trace("Reducing to procedure_invocation\n");
                }
                ;

/*declarations:       declaration declarations
                |
                {
                    Trace("Reducing to declarations\n");
                }
                ;*/
declaration:        constant{
                    // Trace("Reducing to declaration\n");
                }
                |   variable{
                    // Trace("Reducing to declaration\n");
                }
                |   array{
                    // Trace("Reducing to declaration\n");
                }
                ;
//have to be change when you are doing type verify
constant_exp:       
                    exp
                {   
                    //查exp 是不是const
                    if($1.style==CONST_STYLE){
                        $$=$1;
                    }
                    else{
                        printf("error! not a const value\n");
                        return 1;
                    }
                    // Trace("Reducing to exp\n");
                }
                ;

constant:           CONST IDENTIFIERS ASSIGNMENT constant_exp{
                    // const 要被宣告時利用current_lookup function 去看這個id在當前scope裡是否已經被宣告過了
                    
                    if (current_lookup($2.name->c_str())==-1){
                        // 沒有就存值
                        idtuple temp($2.name->c_str(), nowscope, $4.value->c_str(), $4.type, CONST_STYLE, -1);
                        insert($2.name->c_str(),temp);
                        printf("field static int %s = %d\n", $2.name->c_str(), atoi($4.value->c_str()));
                    }else{
                        printf("id redefine\n");
                        return 1;
                    }

                    // Trace("Reducing to constant\n");
                }
                ;
                    // var 要被宣告時利用current_lookup function 去看這個id在當前scope裡是否已經被宣告過了

variable:           VAR IDENTIFIERS type ASSIGNMENT constant_exp{
                        // 沒有就存值
                    if (current_lookup($2.name->c_str())==-1 && $3==$5.type){
                        idtuple temp($2.name->c_str(), nowscope, $5.value->c_str(), $3, VAR_STYLE, -1);
                        insert($2.name->c_str(),temp);
                        if(nowscope!="golbal"){
                            printf("sipush %d\n", atoi($5.value->c_str()));
                            printf("istore %d\n", symbolTables.front().get_idnumber($2.name->c_str()));
                        }else{
                            printf("field static int %s = %d\n", $2.name->c_str(), atoi($5.value->c_str()));
                            // printf("%s %d\n",$2.name->c_str(), symbolTables.front().get_idnumber($2.name->c_str()));
                        }
                    }else{
                        printf("id redefine or wrong type assign\n");
                        return 1;
                    }
                    // Trace("Reducing to variable\n");
                }
                |   VAR IDENTIFIERS type{
                    if (current_lookup($2.name->c_str())==-1){
                        idtuple temp($2.name->c_str(), nowscope, "0", $3, VAR_STYLE, -1);
                        insert($2.name->c_str(),temp);
                        if(nowscope=="golbal"){
                            printf("field static int %s\n", $2.name->c_str());
                        }
                    }else{
                        printf("id redefine\n");
                        return 1;
                    }
                    // Trace("Reducing to variable\n");
                }
                ;

                    // array 要被宣告時利用current_lookup function 去看這個id在當前scope裡是否已經被宣告過了
array:              VAR IDENTIFIERS LEFT_SQUAREBRACKETS int_exp RIGHT_SQUAREBRACKETS type
                {
                    // 沒有就存值
                    if (current_lookup($2.name->c_str())==-1){
                        idtuple temp($2.name->c_str(), nowscope, "0", $6, ARRAY_STYLE, atoi($4.value->c_str()));
                        insert($2.name->c_str(),temp);
                    }else{
                        printf("array redefine\n");
                        return 1;
                    }
                    // Trace("Reducing to array\n");
                }
                ;
// 布林型態的運算
bool_exp:           LEFT_PARENTHESES bool_exp RIGHT_PARENTHESES{$$=$2;}
                |   num_exp RELATIONAL_LESS num_exp {
                        if(($1.type==INT_TYPE || $3.type==INT_TYPE || $1.type==REAL_TYPE || $3.type==REAL_TYPE) && $1.type==$3.type){
                            $$=$1;
                            $$.type = BOOL_TYPE;
                            if(atof($1.value->c_str())<atof($3.value->c_str())){
                                $$.value=new string("1");
                            }else{
                                $$.value=new string("0");
                            }
                            printf("isub\n");
                            printf("iflt L1_%d\n", L_count);
                            printf("iconst_0\n");
                            printf("goto L2_%d\n", L_count);
                            printf("L1_%d: iconst_1\n", L_count);
                            printf("L2_%d:\n", L_count++);
                            printf("nop\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   num_exp RELATIONAL_LESSEQUAL num_exp {
                        if(($1.type==INT_TYPE || $3.type==INT_TYPE || $1.type==REAL_TYPE || $3.type==REAL_TYPE) && $1.type==$3.type){
                            $$=$1;
                            $$.type = BOOL_TYPE;
                            if(atof($1.value->c_str())<=atof($3.value->c_str())){
                                $$.value=new string("1");
                            }else{
                                $$.value=new string("0");
                            }
                            printf("isub\n");
                            printf("ifle L1_%d\n", L_count);
                            printf("iconst_0\n");
                            printf("goto L2_%d\n", L_count);
                            printf("L1_%d: iconst_1\n", L_count);
                            printf("L2_%d:\n", L_count++);
                            printf("nop\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   num_exp RELATIONAL_GREATEREQUAL num_exp {
                        if(($1.type==INT_TYPE || $3.type==INT_TYPE || $1.type==REAL_TYPE || $3.type==REAL_TYPE) && $1.type==$3.type){
                            $$=$1;
                            $$.type = BOOL_TYPE;
                            if(atof($1.value->c_str())>=atof($3.value->c_str())){
                                $$.value=new string("1");
                            }else{
                                $$.value=new string("0");
                            }
                            printf("isub\n");
                            printf("ifge L1_%d\n", L_count);
                            printf("iconst_0\n");
                            printf("goto L2_%d\n", L_count);
                            printf("L1_%d: iconst_1\n", L_count);
                            printf("L2_%d:\n", L_count++);
                            printf("nop\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   num_exp RELATIONAL_GREATER num_exp{
                        if(($1.type==INT_TYPE || $3.type==INT_TYPE || $1.type==REAL_TYPE || $3.type==REAL_TYPE) && $1.type==$3.type){
                            $$=$1;
                            $$.type = BOOL_TYPE;
                            if(atof($1.value->c_str())>atof($3.value->c_str())){
                                $$.value=new string("1");
                            }else{
                                $$.value=new string("0");
                            }
                            printf("isub\n");
                            printf("ifgt L1_%d\n", L_count);
                            printf("iconst_0\n");
                            printf("goto L2_%d\n", L_count);
                            printf("L1_%d: iconst_1\n", L_count);
                            printf("L2_%d:\n", L_count++);
                            printf("nop\n");
                        }else{
                            // symbolTables.front().dump();
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   num_exp RELATIONAL_EQUAL num_exp{
                        if(($1.type==INT_TYPE || $3.type==INT_TYPE || $1.type==REAL_TYPE || $3.type==REAL_TYPE) && $1.type==$3.type){
                            $$=$1;
                            $$.type = BOOL_TYPE;
                            if(atof($1.value->c_str())==atof($3.value->c_str())){
                                $$.value=new string("1");
                            }else{
                                $$.value=new string("0");
                            }
                            printf("isub\n");
                            printf("ifeq L1_%d\n", L_count);
                            printf("iconst_0\n");
                            printf("goto L2_%d\n", L_count);
                            printf("L1_%d: iconst_1\n", L_count);
                            printf("L2_%d:\n", L_count++);
                            printf("nop\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   num_exp RELATIONAL_NOTEQUAL num_exp{
                        if(($1.type==INT_TYPE || $3.type==INT_TYPE || $1.type==REAL_TYPE || $3.type==REAL_TYPE) && $1.type==$3.type){
                            $$=$1;
                            $$.type = BOOL_TYPE;
                            if(atof($1.value->c_str())!=atof($3.value->c_str())){
                                $$.value=new string("1");
                            }else{
                                $$.value=new string("0");
                            }
                            printf("isub\n");
                            printf("ifne L1_%d\n", L_count);
                            printf("iconst_0\n");
                            printf("goto L2_%d\n", L_count);
                            printf("L1_%d: iconst_1\n", L_count);
                            printf("L2_%d:\n", L_count++);
                            printf("nop\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   bool_exp LOGICAL_AND bool_exp{
                        if($1.type==BOOL_TYPE && $3.type==BOOL_TYPE){
                            $$=$1;
                            if((atoi($1.value->c_str())==0) || (atoi($3.value->c_str()))==0){
                                $$.value=new string("0");
                            }else{
                                $$.value=new string("1");
                            }
                            printf("iand\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   bool_exp LOGICAL_OR bool_exp{
                        if($1.type==BOOL_TYPE && $3.type==BOOL_TYPE){
                            $$=$1;
                            if((atoi($1.value->c_str())==1)||(atoi($3.value->c_str()))==1){
                                $$.value=new string("1");
                            }else{
                                $$.value=new string("0");
                            }
                            printf("ior\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   LOGICAL_NOT bool_exp{
                        if($2.type==BOOL_TYPE){
                            $$=$2;
                            if(atoi($2.value->c_str())==0){
                                $$.value=new string("1");
                            }else{
                                $$.value=new string("0");
                            }
                            printf("sipush 1\n");
                            printf("ixor\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   BOOLEANCONSTANTS_TRUE{
                    $$=$1;
                    // printf("iconst_1\n");
                    // Trace("Reducing to bool_exp\n");
                }
                |   BOOLEANCONSTANTS_FALSE{
                    $$=$1;
                    // printf("iconst_0\n");
                    // Trace("Reducing to bool_exp\n");
                }
                |   IDENTIFIERS{
                    if (lookup($1.name->c_str())==1)
                    {
                        $1 = getdata($1.name->c_str());
                        $$=$1;
                        if(symbolTables.front().get_idnumber($1.name->c_str())==-1)
                            printf("getstatic int %s.%s\n", classname.c_str(),$1.name->c_str());
                        else if($1.style==3)
                            printf("iload %d\n", symbolTables.front().get_idnumber($1.name->c_str()));
                        else if($1.style==4)
                            printf("sipush %d\n", atoi($1.value->c_str()));
                    }else{
                        printf("id does not exist\n");
                        return 1;
                    }
                    // Trace("Reducing to bool_exp\n");
                }
                ;
// 所有可以用來表示數字的nonterminal
number:             INTEGERCONSTANTS{
                    $$=$1;
                    if (nowscope!="golbal")
                        printf("sipush %d\n", atoi($$.value->c_str()));
                    // Trace("Reducing to number\n");
                }
                |   REALCONSTANTS{
                    $$=$1;
                    // Trace("Reducing to number\n");
                }
                |   func_exp{
                    $$=$1;
                    // Trace("Reducing to number\n");
                }
                |   array_exp{
                    $$=$1;
                    // Trace("Reducing to number\n");
                }
                |   IDENTIFIERS{
                    if (lookup($1.name->c_str())==1)
                    {
                        $1 = getdata($1.name->c_str());
                        $$=$1;
                        if(symbolTables.front().get_idnumber($1.name->c_str())==-1)
                            printf("getstatic int %s.%s\n", classname.c_str(),$1.name->c_str());
                        else if($1.style==3)
                            printf("iload %d\n", symbolTables.front().get_idnumber($1.name->c_str()));
                        else if($1.style==4)
                            printf("sipush %d\n", atoi($1.value->c_str()));
                    }else{
                        printf("id does not exist\n");
                        return 1;
                    }
                    // Trace("Reducing to number\n");
                }
                ;
// 數字型態的運算
num_exp:            LEFT_PARENTHESES num_exp RIGHT_PARENTHESES{$$=$2;}
                |   num_exp ARITHMETIC_ADDITION num_exp{
                        if($1.type==$3.type && (($1.type==INT_TYPE)||($1.type==REAL_TYPE))){
                            $$ = $1;
                            $$.value = new string(to_string(atof($1.value->c_str())+atof($3.value->c_str())));
                            printf("iadd\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   num_exp ARITHMETIC_SUBTRACTION num_exp{
                        if($1.type==$3.type && (($1.type==INT_TYPE)||($1.type==REAL_TYPE))){
                            $$ = $1;
                            $$.value = new string(to_string(atof($1.value->c_str())-atof($3.value->c_str())));
                            printf("isub\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   num_exp ARITHMETIC_MULTIPLICATION num_exp{
                        if($1.type==$3.type && (($1.type==INT_TYPE)||($1.type==REAL_TYPE))){
                            $$ = $1;
                            $$.value = new string(to_string(atof($1.value->c_str())*atof($3.value->c_str())));
                            printf("imul\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   num_exp ARITHMETIC_DIVIDE num_exp{
                        if($1.type==$3.type && (($1.type==INT_TYPE)||($1.type==REAL_TYPE))){
                            $$ = $1;
                            $$.value = new string(to_string(atof($1.value->c_str())/atof($3.value->c_str())));
                            printf("idiv\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   ARITHMETIC_ADDITION num_exp %prec POSITIVE{
                        $$ = $2;
                        // Trace("Reducing to num_exp\n");
                }
                |   ARITHMETIC_SUBTRACTION num_exp %prec NEGATIVE{
                        $$ = $2;
                        $$.value = new string(to_string(-1.0*atof($2.value->c_str())));
                        printf("ineg\n");
                        // Trace("Reducing to num_exp\n");
                }
                |   number{
                        $$=$1;
                        // Trace("Reducing to num_exp\n");
                }
                ;
// int型態的運算
int_exp:            LEFT_PARENTHESES int_exp RIGHT_PARENTHESES{$$=$2;}
                |   int_exp ARITHMETIC_ADDITION int_exp{
                        if($1.type==$3.type && $1.type==INT_TYPE){
                            $$ = $1;
                            $$.value = new string(to_string(atoi($1.value->c_str())+atoi($3.value->c_str())));
                            printf("iadd\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   int_exp ARITHMETIC_SUBTRACTION int_exp{
                        if($1.type==$3.type && $1.type==INT_TYPE){
                            $$ = $1;
                            $$.value = new string(to_string(atoi($1.value->c_str())-atoi($3.value->c_str())));
                            printf("isub\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   int_exp ARITHMETIC_MULTIPLICATION int_exp{
                        if($1.type==$3.type && $1.type==INT_TYPE){
                            $$ = $1;
                            $$.value = new string(to_string(atoi($1.value->c_str())*atoi($3.value->c_str())));
                            printf("imul\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                |   int_exp ARITHMETIC_DIVIDE int_exp{
                        if($1.type==$3.type && $1.type==INT_TYPE){
                            $$ = $1;
                            $$.value = new string(to_string(atoi($1.value->c_str())/atoi($3.value->c_str())));
                            printf("idiv\n");
                        }else{
                            printf("Error not a same type\n");
                            return 1;
                        }
                    }
                /*|   ARITHMETIC_ADDITION int_exp %prec POSITIVE{
                        $$=$2;
                        Trace("Reducing to int_exp\n");
                    }
                |   ARITHMETIC_SUBTRACTION int_exp %prec NEGATIVE{
                        $$=$2;
                        $$.value = new string(to_string(-atoi($2.value->c_str())));
                        // Trace("Reducing to int_exp\n");
                }*/
                |   INTEGERCONSTANTS{
                        $$=$1;
                        // Trace("Reducing to int_exp\n");
                }
                ;

//array的exp
array_exp:          IDENTIFIERS LEFT_SQUAREBRACKETS exp RIGHT_SQUAREBRACKETS{
                        // 檢查這個array的id是否已經存在
                        if(lookup($1.name->c_str())==1){
                            $$ = getdata($1.name->c_str());
                            $$.style = VAR_STYLE;           //a[0] is a var
                            if ($3.type!=INT_TYPE){
                                printf("index must be int\n");
                                return 1;
                            }
                            if ($1.size){
                                
                            }
                        }else{
                            printf("array id doesn't exist\n");
                            return 1;
                        }
                    // Trace("Reducing to array_exp\n");
                }
                ;
// func的exp
func_exp:           IDENTIFIERS LEFT_PARENTHESES parameters RIGHT_PARENTHESES{
                        // 檢查這個func的id是否已經存在
                        if(lookup($1.name->c_str())==1){
                            $$ = getdata($1.name->c_str());
                            $$.style = VAR_STYLE;
                            std::string arg_name="";           //func() is a var
                            std::list<int>* temp=func_arg.find($1.name->c_str())->second;
                            for (std::list<int>::iterator it=temp->begin();it!=temp->end();++it)
                            {
                                if(it==--temp->end()){
                                    arg_name+=typesname[*it];
                                }else
                                    arg_name+=typesname[*it]+",";
                            }
                            printf("invokestatic %s %s.%s(%s)\n", typesname[$$.type].c_str(), classname.c_str(), $1.name->c_str(), arg_name.c_str());
                        }else{
                            printf("func id doesn't exist\n");
                            return 1;
                        }
                    // Trace("Reducing to func_exp\n");
                }
                ;
parameters:         parameter
                | 
                ;
parameter:          exp COMMA parameter
                |   exp
                {
                    // Trace("Reducing to parameters\n");
                }
                ;
%%

void yyerror(char *msg)
{
    fprintf(stderr, "%s\n", msg);
}

int main(int argc, char **argv)
{
    classname = argv[1];
    printf("class %s\n{\n",argv[1]);
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */
    init_scope();
    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */
    // printf("------symbol table------\n");
    // dump();
    // printf("\n");
    // printf("------func arg------\n");
    // dump_arglist();
    printf("}\n");
}

