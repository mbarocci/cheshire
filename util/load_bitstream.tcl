# Copyright 2026 Michelangelo Barocci, Politecnico di Torino.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may not use this file except in
# compliance with the License, or, at your option, the Apache License version 2.0. You may obtain a copy of
# the License at https://solderpad.org/licenses/SHL-2.1/
#
# Unless required by applicable law or agreed to in writing, any work distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#
# Michelangelo Barocci <michelangelo.barocci@polito.it>

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
###
set_property PROGRAM.FILE {/bitfile/cheshire.zcu102.bit} [get_hw_devices xczu9_0]
set_property PROBES.FILE {/bitfile/cheshire.zcu102.ltx} [get_hw_devices xczu9_0]
set_property FULL_PROBES.FILE {/bitfile/cheshire.zcu102.ltx} [get_hw_devices xczu9_0]
###
current_hw_device [get_hw_devices xczu9_0]
refresh_hw_device [lindex [get_hw_devices xczu9_0] 0]
###
program_hw_devices [get_hw_devices xczu9_0]
###
refresh_hw_device [lindex [get_hw_devices xczu9_0] 0]
###
close_hw_manager
###
put "BITSTREAM LOADED ON ZCU102 BOARD"
exit