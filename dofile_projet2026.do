********************************************************************************
*      PROFIL ET DETERMINANTS DE LA PAUVRETE - SENEGAL 2021                   *
********************************************************************************

* 1. Chargement de la base welfare. L'option 'clear' écrase toute autre base ouverte.
use "C:\Users\DELL 7410\Documents\AHINON_ISE2_A\Pauvreté\AAAA\ehcvm_welfare_sen2021.dta", clear

* 2. Nombre total de ménages dans la base.
count

* 3a. Statistiques descriptives de la consommation par tête.
sum pcexp, detail

* 3b. Vérification que le seuil de pauvreté est unique et bien renseigné.
tab zref

* 4a. Création de la variable binaire de pauvreté.
gen pauv = 1 if pcexp < zref

* 4b. Les non-pauvres prennent la valeur 0.
replace pauv = 0 if pauv == .

* 4c. Répartition brute dans l'échantillon sans pondération.
tab pauv

* 5a. Dictionnaire d'étiquettes pour la variable pauvreté.
label define pv 1 "pauvre" 0 "non-pauvre"

* 5b. Application du dictionnaire à la variable pauv.
label values pauv pv

* 5c. Documentation de la variable.
label variable pauv "pauvrete dans l'echantillon"

* 6a. Suppression préventive de la variable poids si elle existe déjà.
capture drop poids

* 6b. Poids individuel : chaque ménage représente hhweight*hhsize personnes dans la population.
gen poids = hhweight * hhsize
label variable poids "Poids d'echantillonnage de la population"

********************************************************************************
*   QUESTION 1 : INDICES FGT (P0, P1, P2) AVEC INTERVALLES DE CONFIANCE      *
********************************************************************************

* 7. Déclaration du plan de sondage : grappe = unité primaire, milieu = strate.
*    Indispensable pour que les intervalles de confiance soient corrects.
svyset grappe [pw = poids], strata(milieu)

* 8a. Installation du package mpovline.
ssc install mpovline, replace

* 8b. Calcul des trois indices FGT (P0, P1, P2) avec leurs intervalles de confiance.
mpovline pcexp [w = poids], varpl(zref) in(fgt0 fgt1 fgt2)

* 9a. Création du gap de pauvreté normalisé : distance relative au seuil pour les pauvres.
capture drop gap_pauv
gen gap_pauv = max(0, (zref - pcexp) / zref)
label variable gap_pauv "Gap de pauvrete normalise"

* 9b. Carré du gap : pénalise davantage les ménages les plus éloignés du seuil.
capture drop gap2_pauv
gen gap2_pauv = gap_pauv^2
label variable gap2_pauv "Severite de la pauvrete"

* 10a. P0 avec intervalle de confiance à 95% en tenant compte du plan de sondage.
svy: mean pauv

* 10b. P1 avec intervalle de confiance à 95%.
svy: mean gap_pauv

* 10c. P2 avec intervalle de confiance à 95%.
svy: mean gap2_pauv

********************************************************************************
*   QUESTION 2 : INDICES D'INEGALITE AU NIVEAU NATIONAL                      *
********************************************************************************

* 11a. Installation du package ineqdeco.
ssc install ineqdeco, replace

* 11b. Calcul du Gini, des indices de Theil T (GE1), L de Theil (GE0),
*      GE(2) et des indices d'Atkinson (0.5, 1, 2) au niveau national.
ineqdeco pcexp [aw = poids]

* 12a. Installation du package lorenz.
ssc install lorenz, replace

* 12b. Calcul de la courbe de Lorenz et du Gini.
lorenz pcexp [pw = poids], gini

* 12c. Tracé de la courbe de Lorenz nationale.
lorenz graph, title("Courbe de Lorenz de la consommation par tête") ///
             subtitle("Niveau National - Sénégal 2021") ///
             ytitle("Part cumulée de la consommation") ///
             xtitle("Part cumulée de la population") ///
             aspectratio(1) legend(on)

* 12d. Exportation de la courbe en image PNG.
graph export "C:\Users\DELL 7410\Documents\AHINON_ISE2_A\Pauvreté\courbe_lorenz_nationale.png", replace

********************************************************************************
*   QUESTION 3 : DESAGREGATION PAR MILIEU, REGION, GENRE ET INSTRUCTION      *
********************************************************************************

*------------------------------------------------------------------------------
* 3.1 PAR MILIEU DE RESIDENCE
*------------------------------------------------------------------------------

* 13a. Indices FGT par milieu de résidence.
svy: mean pauv, over(milieu)
svy: mean gap_pauv, over(milieu)
svy: mean gap2_pauv, over(milieu)

* 13b. Gini, Theil T, Theil L, GE(2) et Atkinson par milieu de résidence.
ineqdeco pcexp [aw = poids], by(milieu)

* 13c. Courbe de Lorenz superposée par milieu de résidence.
lorenz pcexp [pw = poids], gini over(milieu)
lorenz graph, overlay ///
             title("Courbe de Lorenz par milieu de résidence") ///
             subtitle("Sénégal 2021") ///
             ytitle("Part cumulée de la consommation") ///
             xtitle("Part cumulée de la population") ///
             aspectratio(1) legend(on)
graph export "C:\Users\DELL 7410\Documents\AHINON_ISE2_A\Pauvreté\lorenz_milieu.png", replace

*------------------------------------------------------------------------------
* 3.2 PAR REGION ADMINISTRATIVE
*------------------------------------------------------------------------------

* 14a. Indices FGT par région administrative.
svy: mean pauv, over(region)
svy: mean gap_pauv, over(region)
svy: mean gap2_pauv, over(region)

* 14b. Gini, Theil T, Theil L, GE(2) et Atkinson par région.
ineqdeco pcexp [aw = poids], by(region)

*------------------------------------------------------------------------------
* 3.3 PAR GENRE DU CHEF DE MENAGE
*------------------------------------------------------------------------------

* 15a. Indices FGT par genre du chef de ménage (1=Masculin, 2=Féminin).
svy: mean pauv, over(hgender)
svy: mean gap_pauv, over(hgender)
svy: mean gap2_pauv, over(hgender)

* 15b. Gini, Theil T, Theil L, GE(2) et Atkinson par genre du chef de ménage.
ineqdeco pcexp [aw = poids], by(hgender)

*------------------------------------------------------------------------------
* 3.4 PAR NIVEAU D'INSTRUCTION DU CHEF DE MENAGE
*------------------------------------------------------------------------------

* 16a. Indices FGT par niveau d'instruction du chef de ménage.
*      heduc : 1=Aucun | 3=Primaire | 4=Sec.1 | 6=Sec.2 | 9=Supérieur
svy: mean pauv, over(heduc)
svy: mean gap_pauv, over(heduc)
svy: mean gap2_pauv, over(heduc)

* 16b. Gini, Theil T, Theil L, GE(2) et Atkinson par niveau d'instruction.
ineqdeco pcexp [aw = poids], by(heduc)

********************************************************************************
*   QUESTION 4 : ANALYSE ÉCONOMETRIQUE DES FACTEURS ASSOCIÉS A LA PROBABILITÉ 
*                   POUR UN MÉNAGE D'ÊTRE PAUVRES      *
********************************************************************************
  
**Importation des bases individu (Individu chef de menage)
use"C:\Users\DELL 7410\Documents\AHINON_ISE2_A\Pauvreté\AAAA\ehcvm_individu_sen2021.dta"
keep if lien == 1
tempfile Base_chef
save `Base_chef'


*Variables de pauvreté

gen pauvre = (pcexp < zref)
label var pauvre "Ménage pauvre (pcexp < zref)"
label define lpauvre 0 "Non pauvre" 1 "Pauvre"
label values pauvre lpauvre



* Poids individuel (ménage représente hhsize personnes)
gen wt = hhweight * hhsize
label var wt "Poids pondéré (hhweight × hhsize)"

*Recodage des variables du chef de ménage

** Genre du chef
gen hgender1 = (hgender == 2)
label var hgender1 "Chef de ménage féminin (=1)"

** Milieu de résidence
gen rural = (milieu == 2)
label var rural "Milieu rural (=1)"

** Niveau d'éducation (5 catégories ordonnées)
recode heduc                          ///
    (1   = 0 "Aucun")                ///
    (2 3 = 1 "Primaire")             ///
    (4 7 = 2 "Secondaire 1er cycle") ///
    (5 8 = 3 "Secondaire 2nd cycle") ///
    (6 9 = 4 "Supérieur")            ///
    , gen(educ_cat)
label var educ_cat "Niveau d'instruction du chef (0=Aucun → 4=Sup.)"

** Statut matrimonial du chef
recode hmstat                          ///
    (1   = 1 "Marié monogame")        ///
    (2   = 2 "Marié polygame")        ///
    (3   = 3 "Veuf/Veuve")            ///
    (4 5 = 4 "Divorcé/Séparé")        ///
    (6   = 5 "Célibataire")           ///
    (7   = 5 "Célibataire")           ///
    , gen(mstat_cat)
label var mstat_cat "Statut matrimonial du chef"

* Indicatrices statut matrimonial (réf = Marié monogame)
gen polygame   = (mstat_cat == 2)
gen veuf       = (mstat_cat == 3)
gen divorce    = (mstat_cat == 4)
gen celibataire= (mstat_cat == 5)
label var polygame    "Chef marié polygame (=1)"
label var veuf        "Chef veuf/veuve (=1)"
label var divorce     "Chef divorcé/séparé (=1)"
label var celibataire "Chef célibataire (=1)"


** CSP du chef (catégories)
recode hcsp                                              ///
    (1   = 1 "Cadre sup./moyen")                        ///
    (2   = 1 "Cadre sup./moyen")                        ///
    (3   = 2 "Ouvrier/employé qualifié")                ///
    (4   = 3 "Ouvrier/employé non qualifié")            ///
    (5   = 4 "Travailleur compte propre")               ///
    (6   = 5 "Patron")                                  ///
    (7   = 6 "Travailleur familial")                    ///
    (8   = 7 "Manœuvre/aide ménagère")                  ///
    (9   = 8 "Stagiaire/Apprenti")                      ///
    (10  = 8 "Stagiaire/Apprenti")                      ///
    , gen(csp_cat)
label var csp_cat "CSP du chef de ménage"

* Indicatrice salarié vs non-salarié (réf = salarié qualifié)
gen independant = (hcsp == 5 | hcsp == 6 | hcsp == 7)
gen informel    = (hcsp == 7 | hcsp == 8 | hcsp == 9 | hcsp == 10)
label var independant "Chef travailleur indépendant/patron/familial (=1)"
label var informel    "Chef dans emploi informel (=1)"



* Indicatrice secteur agricole (secteur le + pauvre)
gen chef_agricole = (hbranch == 1 | hbranch == 2)
label var chef_agricole "Chef dans secteur agri/élevage/pêche (=1)"

** Handicap du chef
gen hhandig1 = (hhandig == 1)
label var hhandig1 "Chef en situation de handicap (=1)"

****Fusion des bases welfare et menage


merge 1:1 hhid using "C:\Users\DELL 7410\Documents\AHINON_ISE2_A\Pauvreté\AAAA\ehcvm_menage_sen2021.dta",nogenerate


/*------------------------------------------------------------------
  3a. Recodage des variables du fichier ménage
------------------------------------------------------------------*/

** Accès à l'électricité
gen elec = (elec_ac == 1)
label var elec "Accès à l'électricité (=1)"

** Accès à l'eau potable (source sûre)
gen eau_potable = (eauboi_ss == 1)
label var eau_potable "Accès à l'eau potable source sûre (=1)"


tempfile Base_menage
save `Base_menage'

use `Base_menage',clear
merge 1:1 hhid using `Base_chef', nogenerate


* Tri par identifiant ménage
sort hhid

* Label de la base
label data "EHCVM Sénégal 2021 – Base ménage enrichie (welfare+menage+individu)"

* Sauvegarde
save "base_menage.dta", replace

**** Modèle

global Xvars "hhsize hage hgender1 rural hhandig1 educ_cat polygame informel chef_agricole  elec eau_potable bank"

**** Modèle Probit

probit pauvre $Xvars [pweight=wt]
estimates store probit_model

** Effets marginaux moyens (AME)

margins, dydx(*)


****Modèle Logit

logit pauvre $Xvars [pweight=wt]
estimates store logit_model

** Odds Ratios avec IC 95 %

logit pauvre $Xvars [pweight=wt], or

** Effets marginaux moyens Logit

margins, dydx(*)


** AIC et BIC

estimates stats probit_model logit_model


********************************************************************************
*   QUESTION 5: VOIR RAPPORT      
********************************************************************************

