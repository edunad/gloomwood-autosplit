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

    var mdlSize = vars.gameAssembly.ModuleMemorySize;
    print("[INFO] Gloomwood game version: " + mdlSize);
    if (mdlSize == 29822976) {
        vars.gameStateBase = 0x01AD0B68;
        vars.gameLevelBase = 0x01A9C0F0;
    } else {
        print("[WARNING] Invalid Gloomwood game version");
        print("[WARNING] Could not find pointers");
    }

    vars.gameBase = vars.gameAssembly.BaseAddress;
    vars.ptrGameStateOffset = vars.gameBase + vars.gameStateBase;
    vars.ptrGameLevelOffset = vars.gameBase + vars.gameLevelBase;

	vars.track = new MemoryWatcherList();
    vars.track.Add(new MemoryWatcher<int>(new DeepPointer(vars.ptrGameStateOffset, 0x628, 0, 0x168, 0x20)) { Name = "state" });
    vars.track.Add(new MemoryWatcher<bool>(new DeepPointer(vars.ptrGameStateOffset, 0x580, 0x250, 0x480)) { Name = "alphaMenuVisible" });
    vars.track.Add(new StringWatcher(new DeepPointer(vars.ptrGameLevelOffset, 0x48, 0x38), 255) { Name = "scene" });
}

exit {
	timer.IsGameTimePaused = true; // Pause timer on game crash
}

isLoading {
    return vars.track["state"].Current == 2;
}

start {
    return vars.track["state"].Current == 3 && vars.track["state"].Old != vars.track["state"].Current;
}

update {
    if(vars.track == null) return;
    vars.track.UpdateAll(game);
}

split {
    if(timer.CurrentPhase != TimerPhase.Running) return false;

    if(settings["split_level_change"]) {
        bool validLevel = !vars.track["scene"].Current.Contains("Loading") && !vars.track["scene"].Current.Contains("Title");
        if(!validLevel && vars.track["scene"].Current != vars.track["scene"].Old) {
            print("split level");
            return true;
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
