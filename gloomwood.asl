/*  Gloomwood Autosplitter
    v0.0.1 --- By FailCake (edunad)

    GAME VERSIONS:
    - v0.1.216 = 29822976

    CHANGELOG:
    - Add auto-start
    - WIP: Add split on Alpha menu end
    - Add split on level change
*/


state("Gloomwood", "0.1.216") { }

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

    vars.gameBase = vars.gameAssembly.BaseAddress;
    vars.gameStateBase = 0x00;
    vars.gameLevelBase = 0x00;
    vars.gameMenuBase = 0x00;

    var mdlSize = vars.gameAssembly.ModuleMemorySize;
    print("[INFO] Gloomwood game version: " + mdlSize);
    if (mdlSize == 29822976) {
        vars.gameStateBase = 0x01AADAF0;
        vars.gameLevelBase = 0x01A9C0F0;
        vars.gameMenuBase = 0x01AD09B0;
    } else {
        print("[WARNING] Invalid Gloomwood game version");
        print("[WARNING] Could not find pointers");
    }

    vars.gameBase = vars.gameAssembly.BaseAddress;
    vars.ptrGameStateOffset = vars.gameBase + vars.gameStateBase;
    vars.ptrGameLevelOffset = vars.gameBase + vars.gameLevelBase;
    vars.ptrGameMenuOffset = vars.gameBase + vars.gameMenuBase;

	vars.track = new MemoryWatcherList();
    vars.track.Add(new MemoryWatcher<int>(new DeepPointer(vars.ptrGameStateOffset, 0xD0, 0x8, 0x318, 0x20)) { Name = "state" });
    vars.track.Add(new StringWatcher(new DeepPointer(vars.ptrGameLevelOffset, 0x48, 0x38), 255) { Name = "scene" });
    vars.track.Add(new MemoryWatcher<bool>(new DeepPointer(vars.ptrGameMenuOffset, 0x1F8, 0x608, 0x230, 0x480)) { Name = "alphaMenuVisible" });

    vars.__old_valid_level = "";
}

exit {
	timer.IsGameTimePaused = true; // Pause timer on game crash
}

isLoading {
    return vars.track["state"].Current == 2;
}

start {
    int newState = vars.track["state"].Current;
    int oldState = vars.track["state"].Old;

    if(oldState == newState) return false;
    if(newState < 1 || newState > 3 || oldState < 1 || oldState > 3) return false;

    return newState == 3;
}

update {
    if(vars.track == null) return;
    if(timer.CurrentPhase != TimerPhase.Running && vars.__old_valid_level != "") vars.__old_valid_level = ""; // Cleanup

    vars.track.UpdateAll(game);
}

split {
    if(vars.track == null || timer.CurrentPhase != TimerPhase.Running) return false;

    if(settings["split_level_change"]) {
        string currLevel = vars.track["scene"].Current;
        string oldLevel = vars.track["scene"].Old;

        if(oldLevel != currLevel) {
            bool validLevel = !currLevel.Contains("Loading") && !currLevel.Contains("Title");

            if(validLevel && currLevel != vars.__old_valid_level) {
                print("[split level] OLD: "+ vars.__old_valid_level + " | NEW: " + currLevel);
                vars.__old_valid_level = currLevel;
                return true;
            }
        }
    }

    if(settings["split_alpha_end"]) {
        if(vars.track["alphaMenuVisible"].Current != vars.track["alphaMenuVisible"].Old && vars.track["alphaMenuVisible"].Current) {
            print("alpha end");
            return true;
        }
    }

    return false;
}
