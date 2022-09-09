/*  Gloomwood Autosplitter
    v0.0.2 --- By FailCake (edunad)

    GAME VERSIONS:
    - v0.1.216 = 29822976

    CHANGELOG:
    - Code refactor
*/


state("Gloomwood", "0.1.216") {
    int state : "UnityPlayer.dll", 0x01AADAF0, 0xD0, 0x8, 0x318, 0x20;
    string100 scene : "UnityPlayer.dll", 0x01A9C0F0, 0x48, 0x38;
    bool alphaMenuVisible : "UnityPlayer.dll", 0x01AD09B0, 0x1F8, 0x608, 0x230, 0x480;
}

startup {
    // Settings
    settings.Add("split", true, "Splits");
    settings.Add("split_level_change", false, "Level change", "split");
    settings.Add("split_alpha_end", false, "[Experimental] Alpha End", "split");
}

init {
    if(modules == null) return;

    vars.gameAssembly = modules.Where(m => m.ModuleName == "UnityPlayer.dll").First();
    if(vars.gameAssembly == null) return;

    var mdlSize = vars.gameAssembly.ModuleMemorySize;
    print("[INFO] Gloomwood assembly version: " + mdlSize);
    if (mdlSize == 29822976) {
        version = "0.1.216";
    } else {
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
    return current.state == 2;
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
        if(current.alphaMenuVisible != old.alphaMenuVisible && current.alphaMenuVisible) {
            print("alpha end");
            return true;
        }
    }

    return false;
}
