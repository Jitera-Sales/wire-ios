// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation

/// Reports an error and terminates the application
@noreturn public func fatal(message: String, file: String = __FILE__, line: Int = __LINE__) {
    ZMAssertionDump_NSString("Swift assertion", file, Int32(line), message)
    fatalError(message)
}

/// If the condition is not true, reports an error and terminates the application
public func require(condition: Bool, _ message: String = "", file: String = __FILE__, line: Int = __LINE__) {
    if(!condition) {
        fatal(message, file: file, line: line)
    }
}