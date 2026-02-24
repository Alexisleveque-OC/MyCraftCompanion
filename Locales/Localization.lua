local addonName, MCC = ...

-- Localization Table
MCC.L = {}

local locale = GetLocale()

-- Default (English)
local L = setmetatable({}, {
    __index = function(t, k)
        return k -- Return the key itself if no translation exists
    end
})

if locale == "frFR" then
    -- French Translations
    L["Shopping List (Total Ingredients)"] = "Liste d'achats (Ingrédients Totaux)"
    L["Margin (x):"] = "Marge (x):"
    L["Export Auctionator"] = "Export Auctionator"
    L["Vendor:"] = "Vendeur:"
    L["None"] = "Aucun"
    L["Delete this craft"] = "Supprimer ce craft"
    L["Cap:"] = "Cap:"
    L["Copy this text (Ctrl+C) and import it into Auctionator."] =
    "Copiez ce texte (Ctrl+C) et importez-le dans Auctionator."
    L["Select All"] = "Tout sélectionner"
    L["Left Click: Open/Close Interface"] = "|cffaaaaaaClic gauche : Ouvrir/Fermer l'interface|r"
    L["Drag: Move Button"] = "|cffaaaaaaClic gauche maintenu : Déplacer le bouton|r"
    L["Loaded!"] = "chargé !"
    L["Invalid Recipe"] = "Recette invalide"
    L["Craft restored for"] = "Craft restauré pour"
    L["Craft defined/updated:"] = "Craft défini/mis à jour :"
    L["Bags scanned."] = "Sacs personnages scannés."
    L["Bank scanned."] = "Banque & Warbank scannées."
    L["Removed from favorites:"] = "Retiré des favoris :"
    L["Added to favorites:"] = "Ajouté aux favoris :"
    L["Help"] = "Aide"
    L["Close"] = "Fermer"
    L["Character registered: "] = "Perso enregistré : "
    L["Help_1_Title"] = "1. Enregistrement"
    L["Help_1_Text"] = "Ouvrez vos fenêtres de métiers une première fois pour enregistrer vos personnages dans l'addon."
    L["Help_2_Title"] = "2. Sélection des Crafts"
    L["Help_2_Text"] = "Sélectionnez une recette dans vos favoris via les menus déroulants de chaque colonne."
    L["Help_3_Title"] = "3. Liste de Courses"
    L["Help_3_Text"] =
    "L'addon calcule automatiquement ce qu'il vous manque en scannant vos sacs et votre banque de bataillon."
    L["Help_4_Title"] = "4. Export Auctionator"
    L["Help_4_Text"] = "Utilisez le bouton Export pour créer une liste d'achats rapide dans Auctionator."
    L["Help_Minimap_Title"] = "Bouton Minimap"
    L["Help_Minimap_Text"] =
    "Clic maintenu pour déplacer le bouton.\nClic gauche pour ouvrir l'interface principale."
    L["Needs:"] = "Besoin :"
    L["Owned:"] = "Possède :"
    L["Total Cost:"] = "Coût Total :"
    L["Total Purchases"] = "Prix Total des achats"
    L["Purchases to Make"] = "Achats à effectuer"
    L["Total Sales"] = "Total des ventes"
    L["Craft deleted for"] = "Craft supprimé pour"
    L["Shopping List"] = "Liste d'achats"
    L["FACTORY VIEW"] = "VUE FACTORY"
    L["General Settings"] = "Paramètres Généraux"
    L["Buyer Character"] = "Personnage Acheteur"
    L["Select which character is responsible for buying reagents."] =
    "Sélectionnez le personnage en charge de l'achat des composants."
    L["Profile"] = "Profil"
    L["Equipment Crafter"] = "Fabricant d'Équipement"
    L["Resource Producer"] = "Producteur de Ressources"
    L["None"] = "Aucun"
    L["Note: No buyer character selected means the 'Production Engine' (/mcc process) will not work correctly."] =
    "Note : Si aucun perso acheteur n'est choisi, le 'Moteur de Production' (/mcc process) ne fonctionnera pas correctement."
    -- Update Notes
    L["Note_02_1"] = "|cffffcc00Notes de MAJ :|r Mise en place système de notes."
    L["Note_02_2"] = "|cffffcc00Roadmap :|r Suivi de l'évolution via ROADMAP.md."
    L["Note_02_3"] = "|cffffcc00Localization :|r Support FR/EN."
    L["Note_02_4"] = "|cffffcc00Stabilité :|r Refonte interne."
    L["Note_03_1"] = "|cffffcc00Refonte UI :|r Nouveau look moderne (Style Doré)."
    L["Note_03_2"] = "|cffffcc00Optimisation :|r Code plus propre et globalisé."
    L["Note_03_3"] = "|cffffcc00Préparation :|r Base posée pour Factory View."
    L["Set MCC Craft"] = "Définir Craft MCC"
else
    -- English Translations (Explicit for clarity, though fallback works)
    L["Shopping List (Total Ingredients)"] = "Shopping List (Total Ingredients)"
    L["Margin (x):"] = "Margin (x):"
    L["Export Auctionator"] = "Export Auctionator"
    L["Vendor:"] = "Vendor:"
    L["Delete this craft"] = "Delete this craft"
    L["Cap:"] = "Cap:"
    L["Copy this text (Ctrl+C) and import it into Auctionator."] =
    "Copy this text (Ctrl+C) and import it into Auctionator."
    L["Select All"] = "Select All"
    L["Left Click: Open/Close Interface"] = "|cffaaaaaaLeft Click: Open/Close Interface|r"
    L["Drag: Move Button"] = "|cffaaaaaaDrag: Move Button|r"
    L["Loaded!"] = "loaded!"
    -- Data logs
    L["Invalid Recipe"] = "Invalid Recipe"
    L["Craft restored for"] = "Craft restored for"
    L["Craft defined/updated:"] = "Craft defined/updated:"
    L["Bags scanned."] = "Bags scanned."
    L["Bank scanned."] = "Bank scanned."
    L["Removed from favorites:"] = "Removed from favorites:"
    L["Added to favorites:"] = "Added to favorites:"
    L["Help"] = "Help"
    L["Close"] = "Close"
    L["Character registered: "] = "Character registered: "
    L["Help_1_Title"] = "1. Registration"
    L["Help_1_Text"] = "Open your profession windows once to register your characters in the addon."
    L["Help_2_Title"] = "2. Craft Selection"
    L["Help_2_Text"] = "Select a recipe from your favorites using the dropdown menus in each column."
    L["Help_3_Title"] = "3. Shopping List"
    L["Help_3_Text"] = "The addon automatically calculates what you're missing by scanning your bags and warband bank."
    L["Help_4_Title"] = "4. Auctionator Export"
    L["Help_4_Text"] = "Use the Export button to create a quick shopping list in Auctionator."
    L["Help_Minimap_Title"] = "Minimap Button"
    L["Help_Minimap_Text"] = "Drag the button to move it.\nLeft Click to open the main interface."
    L["Needs:"] = "Needs:"
    L["Owned:"] = "Owned:"
    L["Total Cost:"] = "Total Cost:"
    L["Total Purchases"] = "Total Purchases"
    L["Purchases to Make"] = "Purchases to Make"
    L["Total Sales"] = "Total Sales"
    L["Craft deleted for"] = "Craft deleted for"
    L["Shopping List"] = "Shopping List"
    L["FACTORY VIEW"] = "FACTORY VIEW"
    L["General Settings"] = "General Settings"
    L["Buyer Character"] = "Buyer Character"
    L["Select which character is responsible for buying reagents."] =
    "Select which character is responsible for buying reagents."
    L["Profile"] = "Profile"
    L["Equipment Crafter"] = "Equipment Crafter"
    L["Resource Producer"] = "Resource Producer"
    L["None"] = "None"
    L["Note: No buyer character selected means the 'Production Engine' (/mcc process) will not work correctly."] =
    "Note: No buyer character selected means the 'Production Engine' (/mcc process) will not work correctly."
    -- Update Notes
    L["Note_02_1"] = "|cffffcc00Update Notes:|r Update note system implemented."
    L["Note_02_2"] = "|cffffcc00Roadmap:|r Tracking evolution via ROADMAP.md."
    L["Note_02_3"] = "|cffffcc00Localization:|r FR/EN Support."
    L["Note_02_4"] = "|cffffcc00Stability:|r Internal refactor."
    L["Note_03_1"] = "|cffffcc00UI Refactor:|r New modern look (Gold Style)."
    L["Note_03_2"] = "|cffffcc00Optimization:|r Cleaner and globalized code."
    L["Note_03_3"] = "|cffffcc00Preparation:|r Base set for Factory View."
    L["Set MCC Craft"] = "Set MCC Craft"
end

MCC.L = L
