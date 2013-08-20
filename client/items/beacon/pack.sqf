//@file Version: 1.0
//@file Name: pack.sqf
//@file Author: MercyfulFate
//@file Created: 21/7/2013 16:00
//@file Description: Pack the nearest Spawn Beacon
//@file Argument: [player, player, _action, []] the standard "called by an action" values

#include "mutex.sqf"
#define ANIM "AinvPknlMstpSlayWrflDnon_medic"
#define DURATION MF_ITEMS_SPAWN_BEACON_DURATION
#define ERR_CANCELLED "Packing Spawn Beacon Cancelled"
#define ERR_TOO_FAR_AWAY "Packing Spawn Beacon Failed! You moved too far away from the beacon"
#define ERR_SOMEONE_ELSE_TAKEN "Packing Spawn Beacon Failed! Someone else finished packing it up before you"

private ["_beacon", "_error", "_hasFailed", "_success"];
_beacon = [] call mf_items_spawn_beacon_nearest;
_error = [_beacon] call mf_items_spawn_beacon_can_pack;
if (_error != "") exitWith {[_error, 5] call mf_notify_client};

_hasFailed = {
	private ["_progress", "_beacon", "_caller", "_failed", "_text"];
	_progress = _this select 0;
	_beacon = _this select 1;
	_text = "";
	_failed = true;
	switch (true) do {
		case not(alive player): {}; // player dead, no error msg needed
		case not(vehicle player == player): {};
        case (isNull _beacon): {_text = ERR_SOMEONE_ELSE_TAKEN};
		case not(player distance _beacon < 5): {_text = ERR_TOO_FAR_AWAY};
		case (doCancelAction): {doCancelAction = false; _text = ERR_CANCELLED};
		default {
			_text = format["Spawn Beacon is %1%2 Packed", round(_progress*100), "%"];
			_failed = false;
        };
    };
    [_failed, _text];
};

MUTEX_LOCK_OR_FAIL;
_beacon setVariable ['packing', true, true];
_success =  [DURATION, ANIM, _hasFailed, [_beacon]] call mf_util_playUntil;
_beacon setVariable ['packing', false, true];
MUTEX_UNLOCK;
    
if (_success) then {
    pvar_spawn_beacons = pvar_spawn_beacons - [_beacon];
    publicVariable "pvar_spawn_beacons";
    deleteVehicle _beacon;
	[MF_ITEMS_SPAWN_BEACON, 1] call mf_inventory_add;
    ["You successfully packed the Spawn Beacon", 5] call mf_notify_client;
};