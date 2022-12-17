//
//  GangstureHandModel++.swift
//  Example
//
//  Created by 이유진 on 2022/12/17.
//  Copyright © 2022 Tomoya Hirano. All rights reserved.
//

import UIKit

extension GangstureHandModel{
    func prediction(inputList: [Double]) throws ->
        GangstureHandModelOutput {
            var hand_type = 0.0
            var _1_x = inputList[0]
            var _1_y = inputList[1]
            var _1_z = inputList[2]
            var _1_rx = inputList[3]
            var _1_ry = inputList[4]
            var _1_rz = inputList[5]
            var _2_x = inputList[6]
            var _2_y = inputList[7]
            var _2_z = inputList[8]
            var _2_rx = inputList[9]
            var _2_ry = inputList[10]
            var _2_rz = inputList[11]
            var _3_x = inputList[12]
            var _3_y = inputList[13]
            var _3_z = inputList[14]
            var _3_rx = inputList[15]
            var _3_ry = inputList[16]
            var _3_rz = inputList[17]
            var _4_x = inputList[18]
            var _4_y = inputList[19]
            var _4_z = inputList[20]
            var _4_rx = inputList[21]
            var _4_ry = inputList[22]
            var _4_rz = inputList[23]
            var _5_x = inputList[24]
            var _5_y = inputList[25]
            var _5_z = inputList[26]
            var _5_rx = inputList[27]
            var _5_ry = inputList[28]
            var _5_rz = inputList[29]
            var _6_x = inputList[30]
            var _6_y = inputList[31]
            var _6_z = inputList[32]
            var _6_rx = inputList[33]
            var _6_ry = inputList[34]
            var _6_rz = inputList[35]
            var _7_x = inputList[36]
            var _7_y = inputList[37]
            var _7_z = inputList[38]
            var  _7_rx = inputList[39]
            var  _7_ry = inputList[40]
            var _7_rz = inputList[41]
            var _8_x = inputList[42]
            var _8_y = inputList[43]
            var _8_z = inputList[44]
            var _8_rx = inputList[45]
            var _8_ry = inputList[46]
            var _8_rz = inputList[47]
            var _9_x = inputList[48]
            var _9_y = inputList[49]
            var _9_z = inputList[50]
            var _9_rx = inputList[51]
            var _9_ry = inputList[52]
            var _9_rz = inputList[53]
            var _10_x = inputList[54]
            var _10_y = inputList[55]
            var _10_z = inputList[56]
            var _10_rx = inputList[57]
            var _10_ry = inputList[58]
            var _10_rz = inputList[59]
            var _11_x = inputList[60]
            var _11_y = inputList[61]
            var _11_z = inputList[62]
            var _11_rx = inputList[63]
            var _11_ry = inputList[64]
            var _11_rz = inputList[65]
            var _12_x = inputList[66]
            var _12_y = inputList[67]
            var _12_z = inputList[68]
            var _12_rx = inputList[69]
            var _12_ry = inputList[70]
            var _12_rz = inputList[71]
            var _13_x = inputList[72]
            var _13_y = inputList[73]
            var _13_z = inputList[74]
            var _13_rx = inputList[75]
            var _13_ry = inputList[76]
            var _13_rz = inputList[77]
            var _14_x = inputList[78]
            var _14_y = inputList[79]
            var _14_z = inputList[80]
            var _14_rx = inputList[81]
            var _14_ry = inputList[82]
            var _14_rz = inputList[83]
            var _15_x = inputList[84]
            var _15_y = inputList[85]
            var _15_z = inputList[86]
            var _15_rx = inputList[87]
            var _15_ry = inputList[88]
            var _15_rz = inputList[89]
            var _16_x = inputList[90]
            var _16_y = inputList[91]
            var _16_z = inputList[92]
            var _16_rx = inputList[93]
            var _16_ry = inputList[94]
            var _16_rz = inputList[95]
            var _17_x = inputList[96]
            var _17_y = inputList[97]
            var _17_z = inputList[98]
            var _17_rx = inputList[99]
            var _17_ry = inputList[100]
            var _17_rz = inputList[101]
            var _18_x = inputList[102]
            var _18_y = inputList[103]
            var _18_z = inputList[104]
            var _18_rx = inputList[105]
            var _18_ry = inputList[106]
            var _18_rz = inputList[107]
            var _19_x = inputList[108]
            var _19_y = inputList[109]
            var _19_z = inputList[110]
            var _19_rx = inputList[111]
            var _19_ry = inputList[112]
            var _19_rz = inputList[113]
            var _20_x = inputList[114]
            var _20_y = inputList[115]
            var _20_z = inputList[116]
            var _20_rx = inputList[117]
            var _20_ry = inputList[118]
            var _20_rz = inputList[119]
            var _21_x = inputList[120]
            var _21_y = inputList[121]
            var _21_z = inputList[122]
            var _21_rx = inputList[123]
            var _21_ry = inputList[124]
            var _21_rz = inputList[125]
            let input_ = GangstureHandModelInput(hand_type: hand_type, _1_x: _1_x, _1_y: _1_y, _1_z: _1_z, _1_rx: _1_rx, _1_ry: _1_ry, _1_rz: _1_rz, _2_x: _2_x, _2_y: _2_y, _2_z: _2_z, _2_rx: _2_rx, _2_ry: _2_ry, _2_rz: _2_rz, _3_x: _3_x, _3_y: _3_y, _3_z: _3_z, _3_rx: _3_rx, _3_ry: _3_ry, _3_rz: _3_rz, _4_x: _4_x, _4_y: _4_y, _4_z: _4_z, _4_rx: _4_rx, _4_ry: _4_ry, _4_rz: _4_rz, _5_x: _5_x, _5_y: _5_y, _5_z: _5_z, _5_rx: _5_rx, _5_ry: _5_ry, _5_rz: _5_rz, _6_x: _6_x, _6_y: _6_y, _6_z: _6_z, _6_rx: _6_rx, _6_ry: _6_ry, _6_rz: _6_rz, _7_x: _7_x, _7_y: _7_y, _7_z: _7_z, _7_rx: _7_rx, _7_ry: _7_ry, _7_rz: _7_rz, _8_x: _8_x, _8_y: _8_y, _8_z: _8_z, _8_rx: _8_rx, _8_ry: _8_ry, _8_rz: _8_rz, _9_x: _9_x, _9_y: _9_y, _9_z: _9_z, _9_rx: _9_rx, _9_ry: _9_ry, _9_rz: _9_rz, _10_x: _10_x, _10_y: _10_y, _10_z: _10_z, _10_rx: _10_rx, _10_ry: _10_ry, _10_rz: _10_rz, _11_x: _11_x, _11_y: _11_y, _11_z: _11_z, _11_rx: _11_rx, _11_ry: _11_ry, _11_rz: _11_rz, _12_x: _12_x, _12_y: _12_y, _12_z: _12_z, _12_rx: _12_rx, _12_ry: _12_ry, _12_rz: _12_rz, _13_x: _13_x, _13_y: _13_y, _13_z: _13_z, _13_rx: _13_rx, _13_ry: _13_ry, _13_rz: _13_rz, _14_x: _14_x, _14_y: _14_y, _14_z: _14_z, _14_rx: _14_rx, _14_ry: _14_ry, _14_rz: _14_rz, _15_x: _15_x, _15_y: _15_y, _15_z: _15_z, _15_rx: _15_rx, _15_ry: _15_ry, _15_rz: _15_rz, _16_x: _16_x, _16_y: _16_y, _16_z: _16_z, _16_rx: _16_rx, _16_ry: _16_ry, _16_rz: _16_rz, _17_x: _17_x, _17_y: _17_y, _17_z: _17_z, _17_rx: _17_rx, _17_ry: _17_ry, _17_rz: _17_rz, _18_x: _18_x, _18_y: _18_y, _18_z: _18_z, _18_rx: _18_rx, _18_ry: _18_ry, _18_rz: _18_rz, _19_x: _19_x, _19_y: _19_y, _19_z: _19_z, _19_rx: _19_rx, _19_ry: _19_ry, _19_rz: _19_rz, _20_x: _20_x, _20_y: _20_y, _20_z: _20_z, _20_rx: _20_rx, _20_ry: _20_ry, _20_rz: _20_rz, _21_x: _21_x, _21_y: _21_y, _21_z: _21_z, _21_rx: _21_rx, _21_ry: _21_ry, _21_rz: _21_rz)
            return try self.prediction(input: input_)
        }
    }
