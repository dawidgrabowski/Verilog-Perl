#ident "$Id: VPreprocLex.h,v 1.8 2002/03/11 16:02:26 wsnyder Exp $" //-*- C++ -*-
//*************************************************************************
// DESCRIPTION: Verilog::Preproc: Internal header for lex interfacing
//
// Code available from: http://www.veripool.com/verilog-perl
//
// Authors: Wilson Snyder
//
//*************************************************************************
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of either the GNU General Public License or the
// Perl Artistic License, with the exception that it cannot be placed
// on a CD-ROM or similar media for commercial distribution without the
// prior approval of the author.
//
// Verilator is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Verilator; see the file COPYING.  If not, write to
// the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
// Boston, MA 02111-1307, USA.
//
//*************************************************************************
// This header provides the interface between the lex proper VPreprocLex.l/.cpp
// and the class implementation file VPreproc.cpp
// It is not intended for user applications.
//*************************************************************************

#ifndef _VPREPROCLEX_H_		// Guard
#define _VPREPROCLEX_H_ 1

#include "VFileLine.h"

// Token codes
#define VP_EOF		0

#define VP_INCLUDE	256
#define VP_IFDEF	257
#define VP_IFNDEF	258
#define VP_ENDIF	259
#define VP_UNDEF	260
#define VP_DEFINE	261
#define VP_ELSE		262
#define VP_ELSIF	263

#define VP_SYMBOL	300
#define VP_STRING	301
#define VP_DEFVALUE	302
#define VP_COMMENT	303
#define VP_TEXT		304
#define VP_WHITE	305
#define VP_DEFREF	306
#define VP_ERROR	307


//======================================================================
// Externs created by flex
// We add a prefix so that other lexers/flexers in the same program won't collide.
#ifndef yy_create_buffer
# define yy_create_buffer VPreprocLex_create_buffer
# define yy_delete_buffer VPreprocLex_delete_buffer
# define yy_scan_buffer VPreprocLex_scan_buffer
# define yy_scan_string VPreprocLex_scan_string
# define yy_scan_bytes VPreprocLex_scan_bytes
# define yy_flex_debug VPreprocLex_flex_debug
# define yy_init_buffer VPreprocLex_init_buffer
# define yy_flush_buffer VPreprocLex_flush_buffer
# define yy_load_buffer_state VPreprocLex_load_buffer_state
# define yy_switch_to_buffer VPreprocLex_switch_to_buffer
# define yyin VPreprocLexin
# define yyleng VPreprocLexleng
# define yylex VPreprocLexlex
# define yyout VPreprocLexout
# define yyrestart VPreprocLexrestart
# define yytext VPreprocLextext
#endif

#ifndef YY_BUFFER_STATE
struct yy_buffer_state;
typedef struct yy_buffer_state *YY_BUFFER_STATE;
# define YY_BUF_SIZE 16384
#endif

extern int yylex();
extern void yyrestart(FILE*);
extern char* yytext;
extern int yyleng;
YY_BUFFER_STATE yy_create_buffer ( FILE *file, int size );
void yy_switch_to_buffer( YY_BUFFER_STATE new_buffer );
void yy_delete_buffer( YY_BUFFER_STATE b );

//======================================================================
// Class entry for each per-lexter state

#define KEEPCMT_SUB 2

class VPreprocLex {
  public:	// Used only by VPreprocLex.cpp and VPreproc.cpp
    VFileLine*	m_curFilelinep;	// Current processing point

    ~VPreprocLex() { fclose(m_fp); yy_delete_buffer(m_yyState); }

    // Parse state
    FILE*	m_fp;		// File state is for
    YY_BUFFER_STATE  m_yyState;	// flex input state

    // State to lexer
    static VPreprocLex* s_currentLexp;	// Current lexing point
    int		m_keepComments;	// Emit comments in output text
    bool	m_pedantic;	// Obey standard; don't Substitute `__FILE__ and `__LINE__

    // State from lexer
    string	m_defValue;	// Definition value being built.

    // Called by VPreprocLex.l from lexer
    void appendDefValue(const char* text, int len);
    void lineDirective(const char* text);
    void linenoInc() { m_curFilelinep = m_curFilelinep->create(m_curFilelinep->lineno()+1); }
    // Called by VPreproc.cpp to inform lexer
    void setStateDefValue();
};

#endif // Guard
