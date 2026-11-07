@echo off
rem RS3 server stack. Same settings as the Chaos Theory LAN chain
rem (run_nat_even -> run_nat2_test -> run_test_keep -> run_test -> run.bat),
rem except the Chaos-Theory-only "ct34" extra frames after LOGIN / JOINWAITMODULE,
rem which are OFF by default here. Set RS3_CT34=ct_ps2 before calling to turn them back on.

if "%RS3_CT34%"=="" set "RS3_CT34=off"

rem run_nat_even.bat
set SCCT_NAT_EVEN=1
rem run_nat2_test.bat
set SCCT_DNAS_EXTERNAL=1
set SCCT_KE1_VARIANT=0
set SCCT_NAT_V2=1
rem run_test_keep.bat
set SCCT_CREATE_FULL=1
set SCCT_CLOSE_ON_MEMBER_LEAVE=0
set SCCT_ROOM_MEMBER_LEAVE=1
set SCCT_HOST_JOIN_REPLY=ip
set SCCT_NEW_GROUP_TO_CREATOR=1
set SCCT_JOIN_GROUPINFO=1
set SCCT_R8=single
set SCCT_CLOSE_ON_LOBBY_LEAVE=0
set SCCT_R9=none
set SCCT_9FORM=ref
rem run_test.bat
set SCCT_ACK42=1
set SCCT_LOBBY_CONFIG=0x1C0
set SCCT_PUSH_ROOMS_AFTER_42=1
set SCCT_NEW_GROUP=room
set SCCT_CREATE_ACK=roomid
set SCCT_ROOM_CONFIG=0x1D8

rem RS3 ladder: return exactly the requested number of rows (Chaos Theory gets one extra)
set SCCT_LADDER_COUNT_PLUS1=0
rem RS3 Top 10 ranking needs COUNTRY_ID on every row, even though the game does not ask for it
set SCCT_LADDER_EXTRA_COLS=COUNTRY_ID
rem RS3 has its own ranking file (state\rs3_ladder_stats.json); Chaos Theory keeps state\ladder_stats.json
set SCCT_LADDER_STATS_FILE=rs3_ladder_stats.json
rem RS3 ranking columns: LEVEL = overall level, RATING = points, Top 10 sorted by points
set SCCT_LADDER_RS3=1
rem RS3 match results are not added to the rankings yet (their layout is not mapped)
set SCCT_RANKED_RECORD=0
rem Lobby name shown in the LOBBY list (edit to rename)
set "SCCT_LOBBY_NAME=Rainbow Six 3"
rem Ranking lists only players who have signed in to RS3 (not every account in users.json)
set SCCT_LADDER_SYNC_USERS=0
rem Room master = the logged-in account (RS3 only lists rooms whose master is in the lobby)
set SCCT_ROOM_MASTER=login
rem RS3 lobby player records (MEMBER_JOIN 50 = name, player flag, group id, ip, ip, player info, 0)
set SCCT_MEMBER_FORMAT=rs3
rem NAT ADDRESS byte order for RS3 (CT order made joiners dial the host at a reversed IP, e.g. 218.1.168.192)
set SCCT_NAT_ADDR_ORDER=le
rem RS3 room ids are negative (the game treats group id <= 0 as a room: player count, PLAYERS list cleanup)
rem set to pos to go back to positive room ids
set SCCT_ROOM_ID_SIGN=neg

rem 2026-11-07: RS3_HOST_IP is set by RS3 Server.bat (auto-detected LAN IP for this PC).
rem Falls back to start_online_capture_ext.ps1's own default (192.168.1.113) if unset,
rem e.g. when this script is run standalone during development.
set "HOSTIP_ARG="
if not "%RS3_HOST_IP%"=="" set "HOSTIP_ARG=-HostIP %RS3_HOST_IP%"

echo RS3 stack: ct34 profile = %RS3_CT34%
if not "%RS3_HOST_IP%"=="" echo RS3 stack: host IP = %RS3_HOST_IP%
rem run.bat (with the ct34 profile switchable)
powershell -ExecutionPolicy Bypass -File "%~dp0..\tools\start_online_capture_ext.ps1" -JoinWaitFormat u32le -Keyex2Mode echo-client -WmKeyex2Mode echo-client -PostKe2Push off -WmPostKe2Push off -Ct34Profile %RS3_CT34% -UseFixedRsa %HOSTIP_ARG%
pause
