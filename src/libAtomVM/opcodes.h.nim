## **************************************************************************
##    Copyright 2019 by Davide Bettio <davide@uninstall.it>                 *
##                                                                          *
##    This program is free software; you can redistribute it and/or modify  *
##    it under the terms of the GNU Lesser General Public License as        *
##    published by the Free Software Foundation; either version 2 of the    *
##    License, or (at your option) any later version.                       *
##                                                                          *
##    This program is distributed in the hope that it will be useful,       *
##    but WITHOUT ANY WARRANTY; without even the implied warranty of        *
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
##    GNU General Public License for more details.                          *
##                                                                          *
##    You should have received a copy of the GNU General Public License     *
##    along with this program; if not, write to the                         *
##    Free Software Foundation, Inc.,                                       *
##    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
## *************************************************************************

const
  OP_LABEL* = 1
  OP_FUNC_INFO* = 2
  OP_INT_CALL_END* = 3
  OP_CALL* = 4
  OP_CALL_LAST* = 5
  OP_CALL_ONLY* = 6
  OP_CALL_EXT* = 7
  OP_CALL_EXT_LAST* = 8
  OP_BIF0* = 9
  OP_BIF1* = 10
  OP_BIF2* = 11
  OP_ALLOCATE* = 12
  OP_ALLOCATE_HEAP* = 13
  OP_ALLOCATE_ZERO* = 14
  OP_ALLOCATE_HEAP_ZERO* = 15
  OP_TEST_HEAP* = 16
  OP_KILL* = 17
  OP_DEALLOCATE* = 18
  OP_RETURN* = 19
  OP_SEND* = 20
  OP_REMOVE_MESSAGE* = 21
  OP_TIMEOUT* = 22
  OP_LOOP_REC* = 23
  OP_LOOP_REC_END* = 24
  OP_WAIT* = 25
  OP_WAIT_TIMEOUT* = 26
  OP_IS_LT* = 39
  OP_IS_GE* = 40
  OP_IS_EQUAL* = 41
  OP_IS_NOT_EQUAL* = 42
  OP_IS_EQ_EXACT* = 43
  OP_IS_NOT_EQ_EXACT* = 44
  OP_IS_INTEGER* = 45
  OP_IS_FLOAT* = 46
  OP_IS_NUMBER* = 47
  OP_IS_ATOM* = 48
  OP_IS_PID* = 49
  OP_IS_REFERENCE* = 50
  OP_IS_PORT* = 51
  OP_IS_NIL* = 52
  OP_IS_BINARY* = 53
  OP_IS_LIST* = 55
  OP_IS_NONEMPTY_LIST* = 56
  OP_IS_TUPLE* = 57
  OP_TEST_ARITY* = 58
  OP_SELECT_VAL* = 59
  OP_SELECT_TUPLE_ARITY* = 60
  OP_JUMP* = 61
  OP_MOVE* = 64
  OP_GET_LIST* = 65
  OP_GET_TUPLE_ELEMENT* = 66
  OP_SET_TUPLE_ELEMENT* = 67
  OP_PUT_LIST* = 69
  OP_PUT_TUPLE* = 70
  OP_PUT* = 71
  OP_BADMATCH* = 72
  OP_IF_END* = 73
  OP_CASE_END* = 74
  OP_CALL_FUN* = 75
  OP_IS_FUNCTION* = 77
  OP_CALL_EXT_ONLY* = 78
  OP_BS_PUT_INTEGER* = 89
  OP_BS_PUT_BINARY* = 90
  OP_BS_PUT_STRING* = 92
  OP_MAKE_FUN2* = 103
  OP_TRY* = 104
  OP_TRY_END* = 105
  OP_TRY_CASE* = 106
  OP_TRY_CASE_END* = 107
  OP_BS_INIT2* = 109
  OP_BS_ADD* = 111
  OP_APPLY* = 112
  OP_APPLY_LAST* = 113
  OP_IS_BOOLEAN* = 114
  OP_IS_FUNCTION2* = 115
  OP_BS_START_MATCH2* = 116
  OP_BS_GET_INTEGER2* = 117
  OP_BS_GET_BINARY2* = 119
  OP_BS_SKIP_BITS2* = 120
  OP_BS_TEST_TAIL2* = 121
  OP_BS_SAVE2* = 122
  OP_BS_RESTORE2* = 123
  OP_GC_BIF1* = 124
  OP_GC_BIF2* = 125
  OP_IS_BITSTR* = 129
  OP_BS_CONTEXT_TO_BINARY* = 130
  OP_BS_TEST_UNIT* = 131
  OP_BS_MATCH_STRING* = 132
  OP_BS_APPEND* = 134
  OP_TRIM* = 136
  OP_BS_INIT_BITS* = 137
  OP_RECV_MARK* = 150
  OP_RECV_SET* = 151
  OP_GC_BIF3* = 152
  OP_LINE* = 153
  OP_IS_MAP* = 156
  OP_IS_TAGGED_TUPLE* = 159
  OP_GET_HD* = 162
  OP_GET_TL* = 163
  OP_PUT_TUPLE2* = 164
  OP_BS_GET_TAIL* = 165
  OP_BS_START_MATCH3* = 166
  OP_BS_GET_POSITION* = 167
  OP_BS_SET_POSITION* = 168
