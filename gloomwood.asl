/*  Gloomwood Autosplitter
    v0.0.4 --- By FailCake (edunad)

    GAME VERSIONS:
    - v0.1.217 = 29822976

    CHANGELOG:
    - Fix pointers for the new update
*/


state("Gloomwood", "0.1.217") {
    int state : "UnityPlayer.dll", 0x01A00D40, 0xB0, 0x30, 0xFF0;
    string100 scene : "UnityPlayer.dll", 0x01A9C0F0, 0x48, 0x38;
    int alphaMenuVisible : "UnityPlayer.dll", 0x01A55B90, 0x550, 0x110, 0x18, 0x18, 0, 0x18, 0xF58;
}

startup {
    // Settings
    settings.Add("settings", true, "Settings");
    settings.Add("settings_pause_timer_load", true, "Pause timer on loading", "settings");

    settings.Add("split", true, "Splits");
    settings.Add("split_level_change", true, "Level change", "split");
    settings.Add("split_alpha_end", true, "[Experimental] Alpha End", "split");
}

init {
    if(modules == null) return;

    vars.gameAssembly = modules.Where(m => m.ModuleName == "UnityPlayer.dll").First();
    if(vars.gameAssembly == null) return;

    var mdlSize = vars.gameAssembly.ModuleMemorySize;
    print("[INFO] Gloomwood assembly version: " + mdlSize);
    if (mdlSize == 29822976) {
        version = "0.1.217";
    } else {
        version = "UNKNOWN";

        print("[WARNING] Invalid Gloomwood game version");
        return;
    }

    print("[INFO] Gloomwood game version: " + version);
    vars.__old_valid_level = "";
}

exit {
	timer.IsGameTimePaused = true; // Pause timer on game crash
}

isLoading {
    return settings["settings_pause_timer_load"] && current.state == 2;
}

start {
    int newState = current.state;
    int oldState = old.state;

    if(oldState == newState) return false;
    if(newState < 1 || newState > 3 || oldState < 1 || oldState > 3) return false;

    return newState == 3;
}

update {
    if(timer.CurrentPhase != TimerPhase.Running && vars.__old_valid_level != "") vars.__old_valid_level = ""; // Cleanup
}

split {
    if(timer.CurrentPhase != TimerPhase.Running) return false;

    if(settings["split_level_change"] && current.scene != null) {
        string currLevel = current.scene != null ? current.scene : "";
        string oldLevel = old.scene != null ? old.scene : "";

        if(oldLevel != currLevel) {
            bool validLevel = !currLevel.Contains("Loading") && !currLevel.Contains("Title");

            if(validLevel && currLevel != vars.__old_valid_level) {
                print("[split level] OLD: "+ vars.__old_valid_level + " | NEW: " + currLevel);
                vars.__old_valid_level = currLevel;
                return true;
            }
        }
    }

    if(settings["split_alpha_end"] && current.alphaMenuVisible != null) {
        if(current.alphaMenuVisible != old.alphaMenuVisible && current.alphaMenuVisible == 1) {
            print("alpha end");
            return true;
        }
    }

    return false;
}
