# Az LLM-ek Működése és a Promptolás Művészete

## Gyors bevezetés
- LLM bevezetés. Mit csinál, hogyan működik
- Prompting szerepe a model belső működésében
- "Best practices" az AI segített fejlesztéshez
```layout
x: -1800
y: -300
scale: 1
rotation: 0
```
```motion
preset: focusIn
durationMs: 1100
```

## Az alapok – Sokdimenziós vektortér
- Embeddings: tokenekből vektorok, sokdimenziós térben.
- Jelentés: távolság és irány (szemantikus geometria).
```layout
x: -1400
y: 200
scale: 1
rotation: 0
```
```diagram
type: image
src: 1.png
```
```motion
preset: focusIn
durationMs: 1300
```

## Tokenizálás és embedding vektorok (BPE)
- BPE: a szöveg subwordekre bomlik, token-ID-k jönnek.
- A vektorok hordozzák a jelentést a modell számára.
```layout
x: 100
y: 555
scale: 1
rotation: 0
```
```diagram
type: image
src: 2.png
```
```motion
preset: panTo
durationMs: 1250
```

## Dinamikus kontextus-építés és attention
- Self-attention: a tokenek közti relevancia a teljes kontextusból jön.
- Figyelem (Q/K/V): dinamikus súlyozás minden lépésben.
```layout
x: -700
y: 1600
scale: 1
rotation: 0
```
```diagram
type: image
src: 3.png
```
```motion
preset: revealGroup
durationMs: 1250
```

## Iteráció lépései 
- hogyan választja ki a generált tokeneket
```layout
x: 2200
y: 150
scale: 1
rotation: 0
```
```diagram
type: image
src: 4.png
```
```motion
preset: panTo
durationMs: 1200
```

## Iteráció és finomítás 
- hogyan változik az output a következő iterációban
```layout
x: 1180
y: 450
scale: 1
rotation: 0
```
```diagram
type: image
src: 5.png
```
```motion
preset: revealGroup
durationMs: 1250
```

## Prompting szerepe
- példa eltérő minőségű promptra
```layout
x: 1800
y: 1900
scale: 1
rotation: 0
```
```diagram
type: image
src: 6.png
```
```motion
preset: panTo
durationMs: 1200
```

## A Promptolás Művészete
- Az AI egy multiplier: Csak a meglévő tudásodat szorozza fel.
- Level 1 (Smooth Brain): Vázlatos promptok (pl. "Build Google Docs") = használhatatlan "catfish code".
- Level 3 (Ideal): Tartalmazza a pontos tech stacket, a terminál parancsokat és az architekturális kontextust.
```layout
x: 2800
y: 4200
scale: 1
rotation: 0
```
```diagram
title: Prompt minőség hatás
type: flow
SmoothBrainPrompt -> CatfishCode
IdealPrompt -> StackParancsokKontextus
StackParancsokKontextus -> HasznosKimenet
```
```motion
preset: panTo
durationMs: 1200
```

## A 3-Részes Pattern a "Slop" ellen
Ha túl nagy a feladat, az AI hibázni fog. Bontsd kisebb elemekre, és használd ezt a 3-részes struktúrát minden feature-höz:
1. The Task: Részletes, precíz leírás.
2. Background Info: Dokumentációk, meglévő fájlok, UI/UX képek.
3. The "Do Not" Section: Mit NEM szabad módosítania vagy használnia.
```layout
x: 3800
y: 5300
scale: 1
rotation: 0
```
```diagram
title: 3-reszes minta
type: flow
TheTask -> BackgroundInfo
BackgroundInfo -> DoNotSection
DoNotSection -> KevesebbSlop
```
```motion
preset: zoomOut
durationMs: 1350
```

## Eszközök és Verifikáció (MCP)
- Model Context Protocol (MCP): Kiterjeszti az AI képességeit (pl. legfrissebb API doksik automatikus behúzása, rálátás a Next.js dev tools-ra).
- Rendszerszintű memória: A projekt szintű guidelines.md vagy agent.md fájlok használata.
- Verifikáció: Az AI sosem csak kódol. Mindig generáltass vele teszteket és CLI parancsokat a kód azonnali verifikálásához.
```layout
x: 3300
y: 6400
scale: 1
rotation: 0
```
```diagram
title: AI workflow ellenorzes
type: flow
MCPEsMemoria -> KodGeneralas
KodGeneralas -> TesztGeneralas
TesztGeneralas -> CLIVerifikacio
CLIVerifikacio -> StabilValtozas
```
```motion
preset: focusIn
durationMs: 1200
```

## Eszközök
- IDE: Cursor
- IDE extensions: Gemini Code Assist and Claude Code (VS Studio)
- OpenViking
- Agency Agents
```layout
x: 2300
y: 5400
scale: 1
rotation: 0
```
```diagram
title: Linkek
type: flow
Cursor -> https://cursor.com/
Gemini Code Assist -> https://marketplace.visualstudio.com/items?itemName=Google.geminicodeassist
Claude Code -> https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code
OpenViking -> https://github.com/Open-Viking/OpenViking
Agency Agents -> https://github.com/msitarzewski/agency-agents
```
```motion
preset: focusIn
durationMs: 1200
```
