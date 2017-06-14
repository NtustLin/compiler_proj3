a.out: proj3.y proj3.l
	yacc proj3.y -d
	lex proj3.l
	g++ y.tab.c -ll -std=c++11

