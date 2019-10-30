
<!-- README.md is generated from README.Rmd. Please edit that file -->

# taxadb <img src="man/figures/logo.svg" align="right" alt="" width="120" />

[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![Travis build
status](https://travis-ci.org/cboettig/taxadb.svg?branch=master)](https://travis-ci.org/cboettig/taxadb)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/cboettig/taxadb?branch=master&svg=true)](https://ci.appveyor.com/project/cboettig/taxadb)
[![Coverage
status](https://codecov.io/gh/cboettig/taxadb/branch/master/graph/badge.svg)](https://codecov.io/github/cboettig/taxadb?branch=master)
[![CRAN
status](https://www.r-pkg.org/badges/version/taxadb)](https://cran.r-project.org/package=taxadb)

The goal of `taxadb` is to provide *fast*, *consistent* access to
taxonomic data, supporting common tasks such as resolving taxonomic
names to identifiers, looking up higher classification ranks of given
species, or returning a list of all species below a given rank. These
tasks are particularly common when synthesizing data across large
species assemblies, such as combining occurrence records with trait
records.

Existing approaches to these problems typically rely on web APIs, which
can make them impractical for work with large numbers of species or in
more complex pipelines. Queries and returned formats also differ across
the different taxonomic authorities, making tasks that query multiple
authorities particularly complex. `taxadb` creates a *local* database of
most readily available taxonomic authorities, each of which is
transformed into consistent, standard, and researcher-friendly tabular
formats.

## Install and initial setup

To get started, install the development version directly from GitHub:

``` r
devtools::install_github("cboettig/taxadb")
```

``` r
library(taxadb)
library(dplyr) # Used to illustrate how a typical workflow combines nicely with `dplyr`
```

Create a local copy of the Catalogue of Life (2018) database:

``` r
td_create("col")
#> not overwriting dwc_col
#> not overwriting common_col
```

Read in the species list used by the Breeding Bird Survey:

``` r
bbs_species_list <- system.file("extdata/bbs.tsv", package="taxadb")
bbs <- read.delim(bbs_species_list)
```

## Getting names and ids

Two core functions are `get_ids()` and `get_names()`. These functions
take a vector of names or ids (respectively), and return a vector of ids
or names (respectively). For instance, we can use this to attempt to
resolve all the bird names in the Breeding Bird Survey against the
Catalogue of Life:

``` r
birds <- bbs %>% 
  select(species) %>% 
  mutate(id = get_ids(species, "col"))

head(birds, 10)
#>                          species           id
#> 1         Dendrocygna autumnalis         <NA>
#> 2            Dendrocygna bicolor COL:35517332
#> 3                Anser canagicus COL:35517329
#> 4             Anser caerulescens COL:35517325
#> 5  Chen caerulescens (blue form)         <NA>
#> 6                   Anser rossii COL:35517328
#> 7                Anser albifrons         <NA>
#> 8                Branta bernicla COL:35517301
#> 9      Branta bernicla nigricans COL:35537100
#> 10             Branta hutchinsii COL:35536445
```

Note that some names cannot be resolved to an identifier. This can occur
because of miss-spellings, non-standard formatting, or the use of a
synonym not recognized by the naming provider. Names that cannot be
uniquely resolved because they are known synonyms of multiple different
species will also return `NA`. The `by_name` filtering functions can
help us resolve this last case (see below).

`get_ids()` returns the IDs of accepted names, that is
`dwc:AcceptedNameUsageID`s. We can resolve the IDs into accepted names:

``` r
birds %>% 
  mutate(accepted_name = get_names(id, "col"))
#>                                           species           id
#> 1                          Dendrocygna autumnalis         <NA>
#> 2                             Dendrocygna bicolor COL:35517332
#> 3                                 Anser canagicus COL:35517329
#> 4                              Anser caerulescens COL:35517325
#> 5                   Chen caerulescens (blue form)         <NA>
#> 6                                    Anser rossii COL:35517328
#> 7                                 Anser albifrons         <NA>
#> 8                                 Branta bernicla COL:35517301
#> 9                       Branta bernicla nigricans COL:35537100
#> 10                              Branta hutchinsii COL:35536445
#> 11                              Branta canadensis COL:35517289
#> 12                                    Cygnus olor COL:35517278
#> 13                              Cygnus buccinator         <NA>
#> 14                             Cygnus columbianus         <NA>
#> 15                               Cairina moschata COL:35517495
#> 16                                     Aix sponsa         <NA>
#> 17                                Spatula discors         <NA>
#> 18                             Spatula cyanoptera         <NA>
#> 19                               Spatula clypeata COL:42095596
#> 20                                Mareca strepera         <NA>
#> 21                                Mareca penelope         <NA>
#> 22                               Mareca americana COL:35517378
#> 23                             Anas platyrhynchos COL:35517347
#> 24                       Anas platyrhynchos diazi COL:35537080
#> 25                                  Anas rubripes COL:35517352
#> 26                                 Anas fulvigula COL:35517354
#> 27     Anas platyrhynchos x rubripes or fulvigula         <NA>
#> 28                                     Anas acuta COL:35517358
#> 29                                    Anas crecca COL:35517365
#> 30                             Aythya valisineria         <NA>
#> 31                               Aythya americana COL:35517406
#> 32                                Aythya collaris COL:35517409
#> 33                                Aythya fuligula COL:35517416
#> 34                                  Aythya marila COL:35517411
#> 35                                 Aythya affinis         <NA>
#> 36                        Aythya marila / affinis         <NA>
#> 37                          Somateria spectabilis COL:35517435
#> 38                           Somateria mollissima COL:35517430
#> 39                      Histrionicus histrionicus COL:35517427
#> 40                        Melanitta perspicillata COL:35517444
#> 41                                Melanitta fusca         <NA>
#> 42                            Melanitta americana COL:35517447
#> 43    Melanitta perspicillata / fusca / americana         <NA>
#> 44                              Clangula hyemalis COL:35517426
#> 45                              Bucephala albeola COL:35517425
#> 46                             Bucephala clangula COL:35517421
#> 47                            Bucephala islandica COL:35517424
#> 48                 Bucephala clangula / islandica         <NA>
#> 49                          Lophodytes cucullatus COL:35517455
#> 50                               Mergus merganser COL:35517456
#> 51                                Mergus serrator COL:35517458
#> 52                             Oxyura jamaicensis COL:35517448
#> 53                                 Ortalis vetula COL:35517860
#> 54                                Oreortyx pictus COL:35518013
#> 55                            Colinus virginianus         <NA>
#> 56                            Callipepla squamata COL:35517994
#> 57                         Callipepla californica COL:35517998
#> 58                            Callipepla gambelii COL:35517999
#> 59                            Cyrtonyx montezumae COL:35518019
#> 60                               Alectoris chukar COL:35518025
#> 61                                  Perdix perdix COL:35518031
#> 62                            Phasianus colchicus COL:35518023
#> 63                                 Pavo cristatus COL:35518183
#> 64                                Bonasa umbellus COL:35517920
#> 65                      Centrocercus urophasianus COL:35517981
#> 66                           Centrocercus minimus COL:35529399
#> 67                         Falcipennis canadensis COL:35521381
#> 68                                Lagopus lagopus COL:35517933
#> 69                                   Lagopus muta COL:35529401
#> 70                                Lagopus leucura COL:35529400
#> 71                           Dendragapus obscurus         <NA>
#> 72                        Dendragapus fuliginosus         <NA>
#> 73             Dendragapus obscurus / fuliginosus         <NA>
#> 74                       Tympanuchus phasianellus COL:35517968
#> 75                             Tympanuchus cupido COL:35517962
#> 76                     Tympanuchus pallidicinctus COL:35517966
#> 77                            Meleagris gallopavo COL:35518194
#> 78                          Tachybaptus dominicus         <NA>
#> 79                            Podilymbus podiceps COL:35516905
#> 80                               Podiceps auritus COL:35516884
#> 81                             Podiceps grisegena COL:35516881
#> 82                           Podiceps nigricollis         <NA>
#> 83                      Aechmophorus occidentalis COL:35516904
#> 84                           Aechmophorus clarkii         <NA>
#> 85            Aechmophorus occidentalis / clarkii         <NA>
#> 86                                  Columba livia COL:35518906
#> 87                       Patagioenas leucocephala COL:35528775
#> 88                       Patagioenas flavirostris COL:35528772
#> 89                           Patagioenas fasciata COL:35528771
#> 90                       Streptopelia roseogrisea COL:35518973
#> 91                          Streptopelia decaocto COL:35518967
#> 92                         Streptopelia chinensis COL:35518962
#> 93                                 Columbina inca COL:35518989
#> 94                            Columbina passerina COL:35518979
#> 95                            Columbina talpacoti COL:35518983
#> 96                            Leptotila verreauxi COL:35518991
#> 97                               Zenaida asiatica COL:35518951
#> 98                               Zenaida macroura         <NA>
#> 99                            Coccyzus americanus         <NA>
#> 100                                Coccyzus minor COL:35519476
#> 101                      Coccyzus erythropthalmus COL:35519482
#> 102         Coccyzus americanus / erythropthalmus         <NA>
#> 103                       Geococcyx californianus COL:35519483
#> 104                                Crotophaga ani COL:35519484
#> 105                       Crotophaga sulcirostris COL:35519485
#> 106                        Chordeiles acutipennis COL:35519602
#> 107                              Chordeiles minor COL:35519593
#> 108                         Chordeiles gundlachii COL:35519606
#> 109                Chordeiles acutipennis / minor         <NA>
#> 110                 Chordeiles minor / gundlachii         <NA>
#> 111                        Nyctidromus albicollis COL:35519590
#> 112                      Phalaenoptilus nuttallii COL:35523030
#> 113                      Antrostomus carolinensis         <NA>
#> 114                         Antrostomus vociferus         <NA>
#> 115                          Antrostomus arizonae         <NA>
#> 116                             Cypseloides niger COL:35519607
#> 117                             Chaetura pelagica COL:35519610
#> 118                                Chaetura vauxi COL:35519611
#> 119                          Aeronautes saxatalis COL:35519620
#> 120                               Eugenes fulgens COL:35519642
#> 121                          Lampornis clemenciae COL:35519645
#> 122                            Calothorax lucifer COL:35519628
#> 123                          Archilochus colubris COL:35519629
#> 124                         Archilochus alexandri COL:35519630
#> 125              Archilochus colubris / alexandri         <NA>
#> 126                                  Calypte anna COL:35519632
#> 127                                Calypte costae COL:35519631
#> 128                       Selasphorus platycercus COL:35519633
#> 129                             Selasphorus rufus COL:35519635
#> 130                             Selasphorus sasin COL:35519636
#> 131                     Selasphorus rufus / sasin         <NA>
#> 132                                 Trochilid sp.         <NA>
#> 133                          Selasphorus calliope         <NA>
#> 134                         Cynanthus latirostris COL:35519661
#> 135                         Amazilia yucatanensis COL:35519650
#> 136                            Amazilia violiceps COL:35519656
#> 137                    Coturnicops noveboracensis COL:35518289
#> 138                        Laterallus jamaicensis COL:35518292
#> 139                              Rallus obsoletus         <NA>
#> 140                              Rallus crepitans         <NA>
#> 141                                Rallus elegans COL:35518239
#> 142                    Rallus crepitans / elegans         <NA>
#> 143                               Rallus limicola COL:35518253
#> 144                              Porzana carolina COL:35518273
#> 145                          Porphyrio martinicus COL:35533531
#> 146                           Porphyrio porphyrio COL:35518384
#> 147                             Gallinula galeata         <NA>
#> 148                              Fulica americana COL:35518317
#> 149                               Aramus guarauna COL:35518233
#> 150                           Antigone canadensis         <NA>
#> 151                                Grus americana COL:35518216
#> 152                          Himantopus mexicanus COL:35518641
#> 153                       Recurvirostra americana COL:35518637
#> 154                          Haematopus palliatus         <NA>
#> 155                           Haematopus bachmani COL:35518431
#> 156                          Pluvialis squatarola         <NA>
#> 157                            Pluvialis dominica         <NA>
#> 158                               Pluvialis fulva COL:35521865
#> 159                            Charadrius nivosus COL:35539738
#> 160                           Charadrius wilsonia COL:35518469
#> 161                          Charadrius hiaticula COL:35518456
#> 162                       Charadrius semipalmatus COL:35518458
#> 163                            Charadrius melodus COL:35518459
#> 164                          Charadrius vociferus COL:35518472
#> 165                           Charadrius montanus COL:35518474
#> 166                          Bartramia longicauda COL:35518544
#> 167                          Numenius tahitiensis         <NA>
#> 168                             Numenius phaeopus COL:35518535
#> 169                           Numenius americanus COL:35518529
#> 170                              Limosa lapponica COL:35518611
#> 171                             Limosa haemastica COL:35518614
#> 172                                  Limosa fedoa COL:35518610
#> 173                            Arenaria interpres         <NA>
#> 174                        Arenaria melanocephala COL:35518515
#> 175                              Calidris canutus COL:35518571
#> 176                              Calidris virgata         <NA>
#> 177                            Calidris acuminata COL:35518581
#> 178                           Calidris himantopus COL:35521629
#> 179                           Calidris ruficollis COL:35518588
#> 180                                 Calidris alba COL:35518599
#> 181                               Calidris alpina COL:35518590
#> 182                          Calidris ptilocnemis COL:35518576
#> 183                             Calidris maritima COL:35518575
#> 184                              Calidris bairdii COL:35518584
#> 185                            Calidris minutilla         <NA>
#> 186                          Calidris fuscicollis         <NA>
#> 187                        Calidris subruficollis         <NA>
#> 188                            Calidris melanotos COL:35518582
#> 189                              Calidris pusilla COL:35518597
#> 190                                Calidris mauri COL:35518598
#> 191                                  Calidris sp.         <NA>
#> 192                           Limnodromus griseus COL:35518602
#> 193                       Limnodromus scolopaceus         <NA>
#> 194             Limnodromus griseus / scolopaceus         <NA>
#> 195                                Scolopax minor         <NA>
#> 196                            Gallinago delicata COL:35537410
#> 197                            Actitis hypoleucos COL:35518546
#> 198                            Actitis macularius COL:35537411
#> 199                              Tringa solitaria COL:35518547
#> 200                                 Tringa incana COL:35518562
#> 201                               Tringa flavipes COL:35518552
#> 202                 Tringa melanoleuca / flavipes         <NA>
#> 203                            Tringa semipalmata COL:35539855
#> 204                              Tringa nebularia COL:35518556
#> 205                            Tringa melanoleuca COL:35518551
#> 206                           Phalaropus tricolor COL:35518647
#> 207                            Phalaropus lobatus COL:35518646
#> 208                        Stercorarius pomarinus COL:35518683
#> 209                      Stercorarius parasiticus COL:35518684
#> 210                      Stercorarius longicaudus COL:35518685
#> 211                                    Uria aalge COL:35518835
#> 212                                   Uria lomvia COL:35518839
#> 213                           Uria aalge / lomvia         <NA>
#> 214                                    Alca torda COL:35518833
#> 215                                Cepphus grylle COL:35518844
#> 216                               Cepphus columba COL:35518850
#> 217                      Brachyramphus marmoratus COL:35518854
#> 218                    Brachyramphus brevirostris COL:35518855
#> 219                     Synthliboramphus antiquus         <NA>
#> 220                       Ptychoramphus aleuticus         <NA>
#> 221                         Cerorhinca monocerata COL:35518871
#> 222                        Fratercula corniculata         <NA>
#> 223                           Fratercula cirrhata COL:35518878
#> 224                              Rissa tridactyla         <NA>
#> 225                                   Xema sabini COL:35518749
#> 226                  Chroicocephalus philadelphia COL:35539748
#> 227                    Chroicocephalus ridibundus COL:35539749
#> 228                          Hydrocoloeus minutus COL:35539773
#> 229                            Rhodostethia rosea COL:35518747
#> 230                         Leucophaeus atricilla COL:35539787
#> 231                          Leucophaeus pipixcan COL:35539790
#> 232                               Larus heermanni COL:35518725
#> 233                                   Larus canus COL:35518716
#> 234                            Larus delawarensis COL:35518714
#> 235                            Larus occidentalis COL:35518701
#> 236                            Larus californicus COL:35518713
#> 237                              Larus argentatus COL:35518708
#> 238                              Larus glaucoides COL:35518695
#> 239                                  Larus fuscus COL:35518705
#> 240                            Larus schistisagus COL:35518700
#> 241                             Larus glaucescens COL:35518698
#> 242              Larus occidentalis x glaucescens         <NA>
#> 243                             Larus hyperboreus COL:35518692
#> 244                                 Larus marinus COL:35518699
#> 245                                      Gull sp.         <NA>
#> 246                         Onychoprion aleuticus COL:35539811
#> 247                           Sternula antillarum COL:35539835
#> 248                         Gelochelidon nilotica COL:35518763
#> 249                            Hydroprogne caspia COL:35518813
#> 250                              Chlidonias niger COL:35518827
#> 251                              Sterna dougallii COL:35518771
#> 252                                Sterna hirundo COL:35518768
#> 253                             Sterna paradisaea COL:35518770
#> 254                               Sterna forsteri COL:35518767
#> 255                            Thalasseus maximus COL:35539850
#> 256                       Thalasseus sandvicensis COL:35518811
#> 257                            Thalasseus elegans COL:35518810
#> 258                                      Tern sp.         <NA>
#> 259                                Rynchops niger COL:35521931
#> 260                                Gavia stellata COL:35516879
#> 261                                 Gavia arctica         <NA>
#> 262                                Gavia pacifica COL:35516880
#> 263                                   Gavia immer COL:35516874
#> 264                                 Gavia adamsii COL:35516875
#> 265                                     Gavia sp.         <NA>
#> 266                            Fulmarus glacialis         <NA>
#> 267                          Calonectris diomedea COL:35521268
#> 268                             Puffinus puffinus COL:35516945
#> 269                         Oceanodroma leucorhoa COL:35517007
#> 270                            Mycteria americana COL:35517223
#> 271                           Fregata magnificens COL:35517120
#> 272                               Sula dactylatra COL:35517062
#> 273                                 Sula nebouxii COL:35517065
#> 274                              Sula leucogaster         <NA>
#> 275                                Morus bassanus COL:35517075
#> 276                    Phalacrocorax penicillatus COL:35517085
#> 277                     Phalacrocorax brasilianus         <NA>
#> 278                         Phalacrocorax auritus COL:35517078
#> 279                 Phalacrocorax auritus / carbo         <NA>
#> 280                           Phalacrocorax carbo COL:35517076
#> 281           Phalacrocorax brasilianus / auritus         <NA>
#> 282                       Phalacrocorax pelagicus         <NA>
#> 283                             Phalacrocorax sp.         <NA>
#> 284                               Anhinga anhinga COL:35517114
#> 285                     Pelecanus erythrorhynchos COL:35517050
#> 286                        Pelecanus occidentalis COL:35517051
#> 287                         Botaurus lentiginosus         <NA>
#> 288                             Ixobrychus exilis         <NA>
#> 289                                Ardea herodias COL:35517127
#> 290                   Ardea herodias occidentalis COL:35517134
#> 291                                    Ardea alba COL:35521619
#> 292                              Egretta garzetta COL:35517164
#> 293                                 Egretta thula COL:35517161
#> 294                              Egretta caerulea COL:35517175
#> 295                              Egretta tricolor COL:35517174
#> 296                             Egretta rufescens COL:35517172
#> 297                                 Bubulcus ibis COL:35517154
#> 298                           Butorides virescens         <NA>
#> 299                         Nycticorax nycticorax COL:35517178
#> 300                           Nyctanassa violacea COL:35517187
#> 301 Nycticorax / Nyctanassa nycticorax / violacea         <NA>
#> 302                                    Ardeid sp.         <NA>
#> 303                               Eudocimus albus COL:35517244
#> 304                          Plegadis falcinellus COL:35517239
#> 305                                Plegadis chihi         <NA>
#> 306                  Plegadis falcinellus / chihi         <NA>
#> 307                                Platalea ajaja COL:35517253
#> 308                              Coragyps atratus COL:35517510
#> 309                                Cathartes aura COL:35517504
#> 310           Coragyps / Cathartes atratus / aura         <NA>
#> 311                       Gymnogyps californianus COL:35517511
#> 312                             Pandion haliaetus COL:35517760
#> 313                       Chondrohierax uncinatus COL:35517668
#> 314                          Elanoides forficatus COL:35517521
#> 315                               Elanus leucurus COL:35517515
#> 316                         Rostrhamus sociabilis COL:35517525
#> 317                      Ictinia mississippiensis COL:35521752
#> 318                      Haliaeetus leucocephalus COL:35517643
#> 319                              Circus hudsonius         <NA>
#> 320                            Accipiter striatus         <NA>
#> 321                            Accipiter cooperii COL:35517538
#> 322                            Accipiter gentilis         <NA>
#> 323                                 Accipiter sp.         <NA>
#> 324                       Buteogallus anthracinus COL:35517627
#> 325                          Parabuteo unicinctus COL:35517623
#> 326                      Geranoaetus albicaudatus         <NA>
#> 327                               Buteo plagiatus         <NA>
#> 328                                Buteo lineatus COL:35517587
#> 329                             Buteo platypterus COL:35517593
#> 330                              Buteo brachyurus COL:35517600
#> 331                               Buteo swainsoni COL:35517595
#> 332                             Buteo albonotatus COL:35517596
#> 333                             Buteo jamaicensis COL:35517578
#> 334                     Buteo jamaicensis harlani COL:35517585
#> 335                                 Buteo lagopus COL:35517601
#> 336                                 Buteo regalis COL:35517605
#> 337                                     Buteo sp.         <NA>
#> 338                             Aquila chrysaetos         <NA>
#> 339                                     Tyto alba         <NA>
#> 340                         Psiloscops flammeolus         <NA>
#> 341                         Megascops kennicottii COL:35531250
#> 342                                Megascops asio COL:35531249
#> 343                          Megascops trichopsis COL:35531253
#> 344                              Bubo virginianus COL:35519521
#> 345                               Bubo scandiacus COL:35531274
#> 346                                  Surnia ulula COL:35519534
#> 347                              Glaucidium gnoma COL:35519537
#> 348                        Glaucidium brasilianum COL:35519543
#> 349                           Micrathene whitneyi COL:35519546
#> 350                            Athene cunicularia COL:35519574
#> 351                            Strix occidentalis COL:35519556
#> 352                                   Strix varia COL:35519552
#> 353                                Strix nebulosa COL:35519560
#> 354                                     Asio otus COL:35519562
#> 355                                 Asio flammeus COL:35519565
#> 356                             Aegolius funereus COL:35519567
#> 357                             Aegolius acadicus         <NA>
#> 358                                Trogon elegans COL:35519672
#> 359                           Megaceryle torquata COL:35519680
#> 360                             Megaceryle alcyon COL:35519677
#> 361                        Chloroceryle americana COL:35519682
#> 362                              Melanerpes lewis COL:35519735
#> 363                    Melanerpes erythrocephalus COL:35519725
#> 364                       Melanerpes formicivorus COL:35519728
#> 365                        Melanerpes uropygialis COL:35519737
#> 366                          Melanerpes aurifrons COL:35519733
#> 367                          Melanerpes carolinus COL:35519734
#> 368                        Sphyrapicus thyroideus COL:35519745
#> 369                            Sphyrapicus varius COL:35519739
#> 370                          Sphyrapicus nuchalis COL:35519748
#> 371                             Sphyrapicus ruber COL:35519749
#> 372                               Sphyrapicus sp.         <NA>
#> 373                             Picoides scalaris COL:35519795
#> 374                            Picoides nuttallii COL:35519793
#> 375                            Picoides pubescens COL:35519794
#> 376                             Picoides villosus COL:35519797
#> 377                             Picoides arizonae COL:35530337
#> 378                             Picoides borealis COL:35519792
#> 379                         Picoides albolarvatus COL:35519791
#> 380                             Picoides dorsalis COL:35530338
#> 381                             Picoides arcticus COL:35519785
#> 382                              Colaptes auratus COL:35519696
#> 383                      Colaptes auratus auratus COL:35519699
#> 384                        Colaptes auratus cafer COL:35519700
#> 385      Colaptes auratus auratus x auratus cafer         <NA>
#> 386                           Colaptes chrysoides COL:35521565
#> 387                            Dryocopus pileatus COL:35519707
#> 388                                Woodpecker sp.         <NA>
#> 389                             Caracara cheriway COL:35517763
#> 390                              Falco sparverius COL:35517789
#> 391                             Falco columbarius COL:35517780
#> 392                               Falco femoralis COL:35517777
#> 393                              Falco rusticolus COL:35517766
#> 394                              Falco peregrinus COL:35517771
#> 395                               Falco mexicanus COL:35517770
#> 396                           Myiopsitta monachus COL:35519404
#> 397                               Aratinga nenday         <NA>
#> 398                            Brotogeris chiriri COL:35522395
#> 399             Brotogeris versicolurus / chiriri         <NA>
#> 400                         Amazona viridigenalis COL:35519465
#> 401                            Psittacula krameri COL:35519347
#> 402                       Melopsittacus undulatus COL:35519307
#> 403                           Camptostoma imberbe COL:35519886
#> 404                              Contopus cooperi COL:35521705
#> 405                             Contopus pertinax COL:35519869
#> 406                           Contopus sordidulus COL:35519873
#> 407                               Contopus virens COL:35519872
#> 408                        Empidonax flaviventris COL:35519852
#> 409                           Empidonax virescens COL:35519853
#> 410                             Empidonax alnorum COL:35519854
#> 411                            Empidonax traillii COL:35519855
#> 412                  Empidonax alnorum / traillii         <NA>
#> 413                             Empidonax minimus COL:35519858
#> 414                           Empidonax hammondii COL:35521738
#> 415                            Empidonax wrightii COL:35519861
#> 416                         Empidonax oberholseri COL:35519860
#> 417             Empidonax hammondii / oberholseri         <NA>
#> 418                          Empidonax difficilis COL:35519862
#> 419                        Empidonax occidentalis COL:35521739
#> 420           Empidonax difficilis / occidentalis         <NA>
#> 421                          Empidonax fulvifrons COL:35519866
#> 422                                 Empidonax sp.         <NA>
#> 423                            Sayornis nigricans COL:35519845
#> 424                               Sayornis phoebe         <NA>
#> 425                                 Sayornis saya COL:35519848
#> 426                          Pyrocephalus rubinus COL:35519882
#> 427                        Myiarchus tuberculifer COL:35519835
#> 428                         Myiarchus cinerascens COL:35519832
#> 429                            Myiarchus crinitus COL:35519825
#> 430                          Myiarchus tyrannulus COL:35519828
#> 431                          Pitangus sulphuratus COL:35519819
#> 432                     Myiodynastes luteiventris COL:35519822
#> 433                        Tyrannus melancholicus COL:35519802
#> 434                              Tyrannus couchii COL:35519811
#> 435              Tyrannus melancholicus / couchii         <NA>
#> 436                           Tyrannus vociferans COL:35519808
#> 437                        Tyrannus crassirostris COL:35519812
#> 438                           Tyrannus verticalis COL:35519807
#> 439              Tyrannus vociferans / verticalis         <NA>
#> 440                             Tyrannus tyrannus COL:35519799
#> 441                         Tyrannus dominicensis COL:35519800
#> 442                           Tyrannus forficatus COL:35519813
#> 443                               Tyrannus savana COL:35519814
#> 444                           Lanius ludovicianus COL:35519988
#> 445                               Lanius borealis         <NA>
#> 446                             Vireo atricapilla COL:35520375
#> 447                                 Vireo griseus COL:35520376
#> 448                                  Vireo bellii COL:35520388
#> 449                                Vireo vicinior COL:35520393
#> 450                                 Vireo huttoni COL:35520382
#> 451                              Vireo flavifrons COL:35520394
#> 452                                Vireo cassinii COL:35521940
#> 453                              Vireo solitarius COL:35520395
#> 454                   Vireo cassinii / solitarius         <NA>
#> 455                                Vireo plumbeus COL:35521961
#> 456                     Vireo plumbeus / cassinii         <NA>
#> 457                          Vireo philadelphicus COL:35520407
#> 458                                  Vireo gilvus COL:35520408
#> 459                               Vireo olivaceus COL:35520406
#> 460                              Vireo altiloquus COL:35520401
#> 461                         Perisoreus canadensis COL:35520942
#> 462                              Cyanocorax yncas COL:35520984
#> 463                     Gymnorhinus cyanocephalus COL:35521016
#> 464                           Cyanocitta stelleri COL:35520959
#> 465                           Cyanocitta cristata         <NA>
#> 466                       Aphelocoma coerulescens         <NA>
#> 467                          Aphelocoma insularis COL:35521613
#> 468                        Aphelocoma californica COL:35521612
#> 469                        Aphelocoma woodhouseii COL:35541716
#> 470          Aphelocoma californica / woodhouseii         <NA>
#> 471                         Aphelocoma wollweberi COL:35541928
#> 472                          Nucifraga columbiana COL:35521017
#> 473                                 Pica hudsonia COL:35537441
#> 474                                 Pica nuttalli COL:35520993
#> 475                         Corvus brachyrhynchos         <NA>
#> 476                               Corvus caurinus COL:35521005
#> 477                             Corvus ossifragus         <NA>
#> 478            Corvus brachyrhynchos / ossifragus         <NA>
#> 479              Corvus brachyrhynchos / caurinus         <NA>
#> 480                           Corvus cryptoleucus COL:35520999
#> 481                                  Corvus corax COL:35520994
#> 482                   Corvus cryptoleucus / corax         <NA>
#> 483                               Alauda arvensis COL:35519895
#> 484                          Eremophila alpestris         <NA>
#> 485                                  Progne subis COL:35519949
#> 486                           Tachycineta bicolor COL:35519923
#> 487                        Tachycineta thalassina COL:35519919
#> 488                    Stelgidopteryx serripennis COL:35519932
#> 489                               Riparia riparia COL:35519926
#> 490                      Petrochelidon pyrrhonota         <NA>
#> 491                           Petrochelidon fulva COL:35519946
#> 492              Petrochelidon pyrrhonota / fulva         <NA>
#> 493                               Hirundo rustica COL:35519935
#> 494                          Poecile carolinensis COL:35521867
#> 495                          Poecile atricapillus COL:35521866
#> 496                               Poecile gambeli COL:35521869
#> 497                              Poecile sclateri COL:35521872
#> 498                             Poecile rufescens COL:35521871
#> 499                            Poecile hudsonicus COL:35521870
#> 500           Poecile carolinensis / atricapillus         <NA>
#> 501                Poecile atricapillus / gambeli         <NA>
#> 502             Poecile atricapillus / hudsonicus         <NA>
#> 503                                   Poecile sp.         <NA>
#> 504                         Baeolophus wollweberi COL:35521625
#> 505                          Baeolophus inornatus COL:35521624
#> 506                           Baeolophus ridgwayi COL:35528622
#> 507               Baeolophus inornatus / ridgwayi         <NA>
#> 508                            Baeolophus bicolor COL:35521622
#> 509                      Baeolophus atricristatus COL:35523582
#> 510            Baeolophus bicolor / atricristatus         <NA>
#> 511                           Auriparus flaviceps COL:35520190
#> 512                          Psaltriparus minimus COL:35520194
#> 513                              Sitta canadensis         <NA>
#> 514                            Sitta carolinensis COL:35520202
#> 515                                 Sitta pygmaea COL:35520215
#> 516                                 Sitta pusilla COL:35520212
#> 517                             Certhia americana COL:35520228
#> 518                          Salpinctes obsoletus COL:35520071
#> 519                           Catherpes mexicanus COL:35520068
#> 520                             Troglodytes aedon COL:35520006
#> 521                         Troglodytes pacificus COL:35541899
#> 522                          Troglodytes hiemalis COL:35541898
#> 523              Troglodytes pacificus / hiemalis         <NA>
#> 524                         Cistothorus platensis COL:35520064
#> 525                         Cistothorus palustris COL:35520067
#> 526                      Thryothorus ludovicianus COL:35520043
#> 527                           Thryomanes bewickii COL:35520025
#> 528               Campylorhynchus brunneicapillus COL:35520048
#> 529                           Thryophilus sinaloa COL:35541054
#> 530                           Polioptila caerulea COL:35521101
#> 531                        Polioptila californica COL:35521873
#> 532                           Polioptila melanura COL:35521105
#> 533                Polioptila caerulea / melanura         <NA>
#> 534                             Cinclus mexicanus COL:35520003
#> 535                               Regulus satrapa COL:35521112
#> 536                             Regulus calendula COL:35521117
#> 537                         Phylloscopus borealis COL:35521093
#> 538                              Chamaea fasciata COL:35520238
#> 539                              Luscinia svecica COL:35521075
#> 540                             Oenanthe oenanthe COL:35521072
#> 541                                 Sialia sialis COL:35521061
#> 542                               Sialia mexicana COL:35521066
#> 543                            Sialia currucoides COL:35521071
#> 544                           Myadestes townsendi COL:35521080
#> 545                           Catharus fuscescens COL:35521057
#> 546                              Catharus minimus COL:35521054
#> 547                            Catharus bicknelli COL:35521632
#> 548                            Catharus ustulatus COL:35521049
#> 549                             Catharus guttatus COL:35521041
#> 550                          Hylocichla mustelina COL:35521040
#> 551                            Turdus migratorius         <NA>
#> 552                               Ixoreus naevius COL:35521037
#> 553                        Dumetella carolinensis COL:35520079
#> 554                         Toxostoma curvirostre COL:35520090
#> 555                               Toxostoma rufum         <NA>
#> 556                         Toxostoma longirostre COL:35520083
#> 557                            Toxostoma bendirei COL:35520089
#> 558                           Toxostoma redivivum COL:35520095
#> 559                            Toxostoma lecontei COL:35520098
#> 560                            Toxostoma crissale COL:35520105
#> 561                          Oreoscoptes montanus COL:35520106
#> 562                              Mimus gundlachii COL:35520078
#> 563                             Mimus polyglottos COL:35520075
#> 564                              Sturnus vulgaris COL:35520933
#> 565                          Acridotheres tristis COL:35521510
#> 566                           Bombycilla garrulus COL:35519999
#> 567                           Bombycilla cedrorum COL:35520002
#> 568                Bombycilla garrulus / cedrorum         <NA>
#> 569                            Phainopepla nitens COL:35521122
#> 570                         Peucedramus taeniatus COL:35520273
#> 571                        Euplectes franciscanus COL:35521742
#> 572                             Passer domesticus COL:35520927
#> 573                               Passer montanus COL:35520929
#> 574                      Motacilla tschutschensis COL:35537440
#> 575                                Motacilla alba COL:35519957
#> 576                               Anthus cervinus COL:35519978
#> 577                              Anthus rubescens COL:35521611
#> 578                              Anthus spragueii COL:35519979
#> 579                    Coccothraustes vespertinus COL:35520538
#> 580                           Pinicola enucleator COL:35520563
#> 581                       Leucosticte tephrocotis COL:35520572
#> 582                            Leucosticte atrata COL:35520579
#> 583                         Leucosticte australis COL:35520580
#> 584                          Haemorhous mexicanus COL:35551523
#> 585                          Haemorhous purpureus COL:35551521
#> 586                           Haemorhous cassinii COL:35551522
#> 587   Carpodacus purpureus / cassinii / mexicanus         <NA>
#> 588                              Acanthis flammea COL:35520596
#> 589                           Acanthis hornemanni COL:35520593
#> 590                Carduelis flammea / hornemanni         <NA>
#> 591                             Loxia curvirostra COL:35520612
#> 592               Loxia curvirostra / sinesciuris         <NA>
#> 593                              Loxia leucoptera COL:35520621
#> 594                Loxia curvirostra / leucoptera         <NA>
#> 595                                  Spinus pinus COL:35520600
#> 596                               Spinus psaltria COL:35520608
#> 597                              Spinus lawrencei COL:35520611
#> 598                                Spinus tristis COL:35520603
#> 599                          Calcarius lapponicus COL:35520861
#> 600                             Calcarius ornatus COL:35520865
#> 601                              Calcarius pictus COL:35520864
#> 602                        Rhynchophanes mccownii COL:35551591
#> 603                         Plectrophenax nivalis COL:35520866
#> 604                       Arremonops rufivirgatus COL:35520623
#> 605                              Pipilo chlorurus COL:35520660
#> 606                              Pipilo maculatus COL:35521864
#> 607                       Pipilo erythrophthalmus COL:35520626
#> 608           Pipilo maculatus / erythrophthalmus         <NA>
#> 609                            Aimophila ruficeps COL:35520719
#> 610                                Melozone fusca COL:35551455
#> 611                            Melozone crissalis COL:35551456
#> 612                               Melozone aberti COL:35551457
#> 613                              Peucaea carpalis COL:35551449
#> 614                              Peucaea botterii COL:35551452
#> 615                              Peucaea cassinii COL:35551450
#> 616                            Peucaea aestivalis COL:35551451
#> 617                          Spizelloides arborea COL:35551679
#> 618                            Spizella passerina COL:35520774
#> 619                              Spizella pallida COL:35520778
#> 620                              Spizella breweri COL:35520779
#> 621                              Spizella pusilla         <NA>
#> 622                          Spizella atrogularis COL:35520787
#> 623                           Pooecetes gramineus COL:35520710
#> 624                          Chondestes grammacus         <NA>
#> 625                          Amphispiza bilineata COL:35520736
#> 626                     Artemisiospiza nevadensis COL:35551441
#> 627                          Artemisiospiza belli COL:35551442
#> 628             Artemisiospiza nevadensis / belli         <NA>
#> 629                       Calamospiza melanocorys COL:35520661
#> 630                     Passerculus sandwichensis         <NA>
#> 631                         Ammodramus savannarum COL:35520680
#> 632                            Ammodramus bairdii COL:35520686
#> 633                          Ammodramus henslowii COL:35520687
#> 634                          Ammodramus leconteii COL:35520692
#> 635                            Ammodramus nelsoni COL:35521515
#> 636                         Ammodramus caudacutus COL:35520691
#> 637                          Ammodramus maritimus COL:35520693
#> 638                             Passerella iliaca         <NA>
#> 639                             Melospiza melodia         <NA>
#> 640                           Melospiza lincolnii COL:35520820
#> 641                           Melospiza georgiana COL:35520824
#> 642                        Zonotrichia albicollis         <NA>
#> 643                           Zonotrichia querula COL:35520792
#> 644                        Zonotrichia leucophrys         <NA>
#> 645                       Zonotrichia atricapilla COL:35520799
#> 646                       Junco hyemalis hyemalis COL:35520752
#> 647                       Junco hyemalis oreganus COL:35520757
#> 648                        Junco hyemalis mearnsi COL:35520756
#> 649                         Junco hyemalis aikeni COL:35520751
#> 650                       Junco hyemalis caniceps COL:35538516
#> 651                                Junco hyemalis         <NA>
#> 652                              Junco phaeonotus COL:35520767
#> 653                                Icteria virens COL:35520358
#> 654                 Xanthocephalus xanthocephalus COL:35520424
#> 655                         Dolichonyx oryzivorus COL:35520415
#> 656                               Sturnella magna COL:35520416
#> 657                            Sturnella neglecta COL:35520421
#> 658                    Sturnella magna / neglecta         <NA>
#> 659                               Icterus spurius COL:35520443
#> 660                            Icterus cucullatus COL:35520449
#> 661                             Icterus bullockii COL:35521751
#> 662                            Icterus pectoralis COL:35520447
#> 663                               Icterus gularis COL:35520455
#> 664                           Icterus graduacauda COL:35520444
#> 665                               Icterus galbula COL:35520462
#> 666                   Icterus bullockii x galbula         <NA>
#> 667                   Icterus bullockii / galbula         <NA>
#> 668                             Icterus parisorum COL:35520461
#> 669                           Agelaius phoeniceus         <NA>
#> 670                             Agelaius tricolor COL:35520440
#> 671                         Molothrus bonariensis COL:35520492
#> 672                              Molothrus aeneus COL:35520491
#> 673                                Molothrus ater         <NA>
#> 674                       Molothrus aeneus / ater         <NA>
#> 675                            Euphagus carolinus COL:35520469
#> 676                        Euphagus cyanocephalus COL:35520472
#> 677                            Quiscalus quiscula         <NA>
#> 678                               Quiscalus major         <NA>
#> 679                           Quiscalus mexicanus         <NA>
#> 680                   Quiscalus major / mexicanus         <NA>
#> 681                           Seiurus aurocapilla COL:35537528
#> 682                        Helmitheros vermivorum COL:35537518
#> 683                            Parkesia motacilla COL:35551162
#> 684                       Parkesia noveboracensis COL:35551163
#> 685                         Vermivora chrysoptera COL:35520253
#> 686                          Vermivora cyanoptera COL:35551164
#> 687            Vermivora cyanoptera x chrysoptera         <NA>
#> 688            Vermivora chrysoptera x cyanoptera         <NA>
#> 689                               Mniotilta varia COL:35520249
#> 690                           Protonotaria citrea COL:35520250
#> 691                       Limnothlypis swainsonii COL:35520251
#> 692                         Oreothlypis peregrina COL:35551167
#> 693                            Oreothlypis celata COL:35551168
#> 694                            Oreothlypis luciae COL:35551170
#> 695                       Oreothlypis ruficapilla COL:35551171
#> 696                         Oreothlypis virginiae COL:35551172
#> 697                              Oporornis agilis COL:35520334
#> 698                            Geothlypis tolmiei COL:35551176
#> 699                       Geothlypis philadelphia COL:35551177
#> 700                            Geothlypis formosa COL:35551178
#> 701                            Geothlypis trichas COL:35520339
#> 702                             Setophaga citrina COL:35551182
#> 703                           Setophaga ruticilla COL:35520369
#> 704                          Setophaga kirtlandii COL:35551183
#> 705                             Setophaga tigrina COL:35551184
#> 706                             Setophaga cerulea COL:35551185
#> 707                           Setophaga americana COL:35551186
#> 708                           Setophaga pitiayumi COL:35551187
#> 709                            Setophaga magnolia COL:35551188
#> 710                            Setophaga castanea COL:35551189
#> 711                               Setophaga fusca COL:35551190
#> 712                            Setophaga petechia COL:35551192
#> 713                        Setophaga pensylvanica COL:35551193
#> 714                             Setophaga striata COL:35551194
#> 715                        Setophaga caerulescens COL:35551195
#> 716                            Setophaga palmarum COL:35551196
#> 717                               Setophaga pinus COL:35551198
#> 718                   Setophaga coronata coronata COL:35551199
#> 719                   Setophaga coronata audoboni         <NA>
#> 720                            Setophaga coronata COL:35551199
#> 721                            Setophaga dominica COL:35551202
#> 722                            Setophaga discolor COL:35551205
#> 723                             Setophaga graciae COL:35551209
#> 724                          Setophaga nigrescens COL:35551210
#> 725                           Setophaga townsendi COL:35551211
#> 726                        Setophaga occidentalis COL:35551212
#> 727              Icterus townsendi x occidentalis         <NA>
#> 728            Setophaga townsendi / occidentalis         <NA>
#> 729                         Setophaga chrysoparia COL:35551213
#> 730                              Setophaga virens COL:35551214
#> 731                         Cardellina canadensis COL:35551232
#> 732                            Cardellina pusilla COL:35551233
#> 733                         Cardellina rubrifrons COL:35520362
#> 734                              Myioborus pictus COL:35520374
#> 735                                 Piranga flava COL:35521127
#> 736                                 Piranga rubra COL:35521131
#> 737                              Piranga olivacea         <NA>
#> 738                           Piranga ludoviciana COL:35521125
#> 739                         Cardinalis cardinalis         <NA>
#> 740                           Cardinalis sinuatus COL:35520504
#> 741              Cardinalis cardinalis / sinuatus         <NA>
#> 742                       Pheucticus ludovicianus COL:35520509
#> 743                     Pheucticus melanocephalus COL:35520510
#> 744                            Passerina caerulea COL:35537521
#> 745                              Passerina amoena COL:35520519
#> 746                              Passerina cyanea COL:35520518
#> 747                     Passerina amoena x cyanea         <NA>
#> 748                          Passerina versicolor COL:35520520
#> 749                               Passerina ciris COL:35520524
#> 750                               Spiza americana COL:35520531
#>                       accepted_name
#> 1                              <NA>
#> 2               Dendrocygna bicolor
#> 3                     Chen canagica
#> 4                 Chen caerulescens
#> 5                              <NA>
#> 6                       Chen rossii
#> 7                              <NA>
#> 8                   Branta bernicla
#> 9         Branta bernicla nigricans
#> 10                Branta hutchinsii
#> 11                Branta canadensis
#> 12                      Cygnus olor
#> 13                             <NA>
#> 14                             <NA>
#> 15                 Cairina moschata
#> 16                             <NA>
#> 17                             <NA>
#> 18                             <NA>
#> 19                    Anas clypeata
#> 20                             <NA>
#> 21                             <NA>
#> 22                   Anas americana
#> 23               Anas platyrhynchos
#> 24         Anas platyrhynchos diazi
#> 25                    Anas rubripes
#> 26                   Anas fulvigula
#> 27                             <NA>
#> 28                       Anas acuta
#> 29                      Anas crecca
#> 30                             <NA>
#> 31                 Aythya americana
#> 32                  Aythya collaris
#> 33                  Aythya fuligula
#> 34                    Aythya marila
#> 35                             <NA>
#> 36                             <NA>
#> 37            Somateria spectabilis
#> 38             Somateria mollissima
#> 39        Histrionicus histrionicus
#> 40          Melanitta perspicillata
#> 41                             <NA>
#> 42        Melanitta nigra americana
#> 43                             <NA>
#> 44                Clangula hyemalis
#> 45                Bucephala albeola
#> 46               Bucephala clangula
#> 47              Bucephala islandica
#> 48                             <NA>
#> 49            Lophodytes cucullatus
#> 50                 Mergus merganser
#> 51                  Mergus serrator
#> 52               Oxyura jamaicensis
#> 53                   Ortalis vetula
#> 54                  Oreortyx pictus
#> 55                             <NA>
#> 56              Callipepla squamata
#> 57           Callipepla californica
#> 58              Callipepla gambelii
#> 59              Cyrtonyx montezumae
#> 60                 Alectoris chukar
#> 61                    Perdix perdix
#> 62              Phasianus colchicus
#> 63                   Pavo cristatus
#> 64                  Bonasa umbellus
#> 65        Centrocercus urophasianus
#> 66             Centrocercus minimus
#> 67           Falcipennis canadensis
#> 68                  Lagopus lagopus
#> 69                     Lagopus muta
#> 70                  Lagopus leucura
#> 71                             <NA>
#> 72                             <NA>
#> 73                             <NA>
#> 74         Tympanuchus phasianellus
#> 75               Tympanuchus cupido
#> 76       Tympanuchus pallidicinctus
#> 77              Meleagris gallopavo
#> 78                             <NA>
#> 79              Podilymbus podiceps
#> 80                 Podiceps auritus
#> 81               Podiceps grisegena
#> 82                             <NA>
#> 83        Aechmophorus occidentalis
#> 84                             <NA>
#> 85                             <NA>
#> 86                    Columba livia
#> 87         Patagioenas leucocephala
#> 88         Patagioenas flavirostris
#> 89             Patagioenas fasciata
#> 90         Streptopelia roseogrisea
#> 91            Streptopelia decaocto
#> 92           Streptopelia chinensis
#> 93                   Columbina inca
#> 94              Columbina passerina
#> 95              Columbina talpacoti
#> 96              Leptotila verreauxi
#> 97                 Zenaida asiatica
#> 98                             <NA>
#> 99                             <NA>
#> 100                  Coccyzus minor
#> 101        Coccyzus erythropthalmus
#> 102                            <NA>
#> 103         Geococcyx californianus
#> 104                  Crotophaga ani
#> 105         Crotophaga sulcirostris
#> 106          Chordeiles acutipennis
#> 107                Chordeiles minor
#> 108           Chordeiles gundlachii
#> 109                            <NA>
#> 110                            <NA>
#> 111          Nyctidromus albicollis
#> 112        Phalaenoptilus nuttallii
#> 113                            <NA>
#> 114                            <NA>
#> 115                            <NA>
#> 116               Cypseloides niger
#> 117               Chaetura pelagica
#> 118                  Chaetura vauxi
#> 119            Aeronautes saxatalis
#> 120                 Eugenes fulgens
#> 121            Lampornis clemenciae
#> 122              Calothorax lucifer
#> 123            Archilochus colubris
#> 124           Archilochus alexandri
#> 125                            <NA>
#> 126                    Calypte anna
#> 127                  Calypte costae
#> 128         Selasphorus platycercus
#> 129               Selasphorus rufus
#> 130               Selasphorus sasin
#> 131                            <NA>
#> 132                            <NA>
#> 133                            <NA>
#> 134           Cynanthus latirostris
#> 135           Amazilia yucatanensis
#> 136              Amazilia violiceps
#> 137      Coturnicops noveboracensis
#> 138          Laterallus jamaicensis
#> 139                            <NA>
#> 140                            <NA>
#> 141                  Rallus elegans
#> 142                            <NA>
#> 143                 Rallus limicola
#> 144                Porzana carolina
#> 145             Porphyrio martinica
#> 146             Porphyrio porphyrio
#> 147                            <NA>
#> 148                Fulica americana
#> 149                 Aramus guarauna
#> 150                            <NA>
#> 151                  Grus americana
#> 152            Himantopus mexicanus
#> 153         Recurvirostra americana
#> 154                            <NA>
#> 155             Haematopus bachmani
#> 156                            <NA>
#> 157                            <NA>
#> 158                 Pluvialis fulva
#> 159              Charadrius nivosus
#> 160             Charadrius wilsonia
#> 161            Charadrius hiaticula
#> 162         Charadrius semipalmatus
#> 163              Charadrius melodus
#> 164            Charadrius vociferus
#> 165             Charadrius montanus
#> 166            Bartramia longicauda
#> 167                            <NA>
#> 168               Numenius phaeopus
#> 169             Numenius americanus
#> 170                Limosa lapponica
#> 171               Limosa haemastica
#> 172                    Limosa fedoa
#> 173                            <NA>
#> 174          Arenaria melanocephala
#> 175                Calidris canutus
#> 176                            <NA>
#> 177              Calidris acuminata
#> 178             Calidris himantopus
#> 179             Calidris ruficollis
#> 180                   Calidris alba
#> 181                 Calidris alpina
#> 182            Calidris ptilocnemis
#> 183               Calidris maritima
#> 184                Calidris bairdii
#> 185                            <NA>
#> 186                            <NA>
#> 187                            <NA>
#> 188              Calidris melanotos
#> 189                Calidris pusilla
#> 190                  Calidris mauri
#> 191                            <NA>
#> 192             Limnodromus griseus
#> 193                            <NA>
#> 194                            <NA>
#> 195                            <NA>
#> 196              Gallinago delicata
#> 197              Actitis hypoleucos
#> 198              Actitis macularius
#> 199                Tringa solitaria
#> 200                   Tringa incana
#> 201                 Tringa flavipes
#> 202                            <NA>
#> 203              Tringa semipalmata
#> 204                Tringa nebularia
#> 205              Tringa melanoleuca
#> 206             Phalaropus tricolor
#> 207              Phalaropus lobatus
#> 208          Stercorarius pomarinus
#> 209        Stercorarius parasiticus
#> 210        Stercorarius longicaudus
#> 211                      Uria aalge
#> 212                     Uria lomvia
#> 213                            <NA>
#> 214                      Alca torda
#> 215                  Cepphus grylle
#> 216                 Cepphus columba
#> 217        Brachyramphus marmoratus
#> 218      Brachyramphus brevirostris
#> 219                            <NA>
#> 220                            <NA>
#> 221           Cerorhinca monocerata
#> 222                            <NA>
#> 223             Fratercula cirrhata
#> 224                            <NA>
#> 225                     Xema sabini
#> 226    Chroicocephalus philadelphia
#> 227      Chroicocephalus ridibundus
#> 228            Hydrocoloeus minutus
#> 229              Rhodostethia rosea
#> 230           Leucophaeus atricilla
#> 231            Leucophaeus pipixcan
#> 232                 Larus heermanni
#> 233                     Larus canus
#> 234              Larus delawarensis
#> 235              Larus occidentalis
#> 236              Larus californicus
#> 237                Larus argentatus
#> 238                Larus glaucoides
#> 239                    Larus fuscus
#> 240              Larus schistisagus
#> 241               Larus glaucescens
#> 242                            <NA>
#> 243               Larus hyperboreus
#> 244                   Larus marinus
#> 245                            <NA>
#> 246           Onychoprion aleuticus
#> 247             Sternula antillarum
#> 248           Gelochelidon nilotica
#> 249              Hydroprogne caspia
#> 250                Chlidonias niger
#> 251                Sterna dougallii
#> 252                  Sterna hirundo
#> 253               Sterna paradisaea
#> 254                 Sterna forsteri
#> 255              Thalasseus maximus
#> 256         Thalasseus sandvicensis
#> 257              Thalasseus elegans
#> 258                            <NA>
#> 259                  Rynchops niger
#> 260                  Gavia stellata
#> 261                            <NA>
#> 262                  Gavia pacifica
#> 263                     Gavia immer
#> 264                   Gavia adamsii
#> 265                            <NA>
#> 266                            <NA>
#> 267            Calonectris diomedea
#> 268               Puffinus puffinus
#> 269           Oceanodroma leucorhoa
#> 270              Mycteria americana
#> 271             Fregata magnificens
#> 272                 Sula dactylatra
#> 273                   Sula nebouxii
#> 274                            <NA>
#> 275                  Morus bassanus
#> 276      Phalacrocorax penicillatus
#> 277                            <NA>
#> 278           Phalacrocorax auritus
#> 279                            <NA>
#> 280             Phalacrocorax carbo
#> 281                            <NA>
#> 282                            <NA>
#> 283                            <NA>
#> 284                 Anhinga anhinga
#> 285       Pelecanus erythrorhynchos
#> 286          Pelecanus occidentalis
#> 287                            <NA>
#> 288                            <NA>
#> 289                  Ardea herodias
#> 290     Ardea herodias occidentalis
#> 291                      Ardea alba
#> 292                Egretta garzetta
#> 293                   Egretta thula
#> 294                Egretta caerulea
#> 295                Egretta tricolor
#> 296               Egretta rufescens
#> 297                   Bubulcus ibis
#> 298                            <NA>
#> 299           Nycticorax nycticorax
#> 300             Nyctanassa violacea
#> 301                            <NA>
#> 302                            <NA>
#> 303                 Eudocimus albus
#> 304            Plegadis falcinellus
#> 305                            <NA>
#> 306                            <NA>
#> 307                  Platalea ajaja
#> 308                Coragyps atratus
#> 309                  Cathartes aura
#> 310                            <NA>
#> 311         Gymnogyps californianus
#> 312               Pandion haliaetus
#> 313         Chondrohierax uncinatus
#> 314            Elanoides forficatus
#> 315                 Elanus leucurus
#> 316           Rostrhamus sociabilis
#> 317        Ictinia mississippiensis
#> 318        Haliaeetus leucocephalus
#> 319                            <NA>
#> 320                            <NA>
#> 321              Accipiter cooperii
#> 322                            <NA>
#> 323                            <NA>
#> 324         Buteogallus anthracinus
#> 325            Parabuteo unicinctus
#> 326                            <NA>
#> 327                            <NA>
#> 328                  Buteo lineatus
#> 329               Buteo platypterus
#> 330                Buteo brachyurus
#> 331                 Buteo swainsoni
#> 332               Buteo albonotatus
#> 333               Buteo jamaicensis
#> 334       Buteo jamaicensis harlani
#> 335                   Buteo lagopus
#> 336                   Buteo regalis
#> 337                            <NA>
#> 338                            <NA>
#> 339                            <NA>
#> 340                            <NA>
#> 341           Megascops kennicottii
#> 342                  Megascops asio
#> 343            Megascops trichopsis
#> 344                Bubo virginianus
#> 345                 Bubo scandiacus
#> 346                    Surnia ulula
#> 347                Glaucidium gnoma
#> 348          Glaucidium brasilianum
#> 349             Micrathene whitneyi
#> 350              Athene cunicularia
#> 351              Strix occidentalis
#> 352                     Strix varia
#> 353                  Strix nebulosa
#> 354                       Asio otus
#> 355                   Asio flammeus
#> 356               Aegolius funereus
#> 357                            <NA>
#> 358                  Trogon elegans
#> 359             Megaceryle torquata
#> 360               Megaceryle alcyon
#> 361          Chloroceryle americana
#> 362                Melanerpes lewis
#> 363      Melanerpes erythrocephalus
#> 364         Melanerpes formicivorus
#> 365          Melanerpes uropygialis
#> 366            Melanerpes aurifrons
#> 367            Melanerpes carolinus
#> 368          Sphyrapicus thyroideus
#> 369              Sphyrapicus varius
#> 370            Sphyrapicus nuchalis
#> 371               Sphyrapicus ruber
#> 372                            <NA>
#> 373               Picoides scalaris
#> 374              Picoides nuttallii
#> 375              Picoides pubescens
#> 376               Picoides villosus
#> 377               Picoides arizonae
#> 378               Picoides borealis
#> 379           Picoides albolarvatus
#> 380               Picoides dorsalis
#> 381               Picoides arcticus
#> 382                Colaptes auratus
#> 383        Colaptes auratus auratus
#> 384          Colaptes auratus cafer
#> 385                            <NA>
#> 386             Colaptes chrysoides
#> 387              Dryocopus pileatus
#> 388                            <NA>
#> 389               Caracara cheriway
#> 390                Falco sparverius
#> 391               Falco columbarius
#> 392                 Falco femoralis
#> 393                Falco rusticolus
#> 394                Falco peregrinus
#> 395                 Falco mexicanus
#> 396             Myiopsitta monachus
#> 397                            <NA>
#> 398              Brotogeris chiriri
#> 399                            <NA>
#> 400           Amazona viridigenalis
#> 401              Psittacula krameri
#> 402         Melopsittacus undulatus
#> 403             Camptostoma imberbe
#> 404                Contopus cooperi
#> 405               Contopus pertinax
#> 406             Contopus sordidulus
#> 407                 Contopus virens
#> 408          Empidonax flaviventris
#> 409             Empidonax virescens
#> 410               Empidonax alnorum
#> 411              Empidonax traillii
#> 412                            <NA>
#> 413               Empidonax minimus
#> 414             Empidonax hammondii
#> 415              Empidonax wrightii
#> 416           Empidonax oberholseri
#> 417                            <NA>
#> 418            Empidonax difficilis
#> 419          Empidonax occidentalis
#> 420                            <NA>
#> 421            Empidonax fulvifrons
#> 422                            <NA>
#> 423              Sayornis nigricans
#> 424                            <NA>
#> 425                   Sayornis saya
#> 426            Pyrocephalus rubinus
#> 427          Myiarchus tuberculifer
#> 428           Myiarchus cinerascens
#> 429              Myiarchus crinitus
#> 430            Myiarchus tyrannulus
#> 431            Pitangus sulphuratus
#> 432       Myiodynastes luteiventris
#> 433          Tyrannus melancholicus
#> 434                Tyrannus couchii
#> 435                            <NA>
#> 436             Tyrannus vociferans
#> 437          Tyrannus crassirostris
#> 438             Tyrannus verticalis
#> 439                            <NA>
#> 440               Tyrannus tyrannus
#> 441           Tyrannus dominicensis
#> 442             Tyrannus forficatus
#> 443                 Tyrannus savana
#> 444             Lanius ludovicianus
#> 445                            <NA>
#> 446               Vireo atricapilla
#> 447                   Vireo griseus
#> 448                    Vireo bellii
#> 449                  Vireo vicinior
#> 450                   Vireo huttoni
#> 451                Vireo flavifrons
#> 452                  Vireo cassinii
#> 453                Vireo solitarius
#> 454                            <NA>
#> 455                  Vireo plumbeus
#> 456                            <NA>
#> 457            Vireo philadelphicus
#> 458                    Vireo gilvus
#> 459                 Vireo olivaceus
#> 460                Vireo altiloquus
#> 461           Perisoreus canadensis
#> 462                Cyanocorax yncas
#> 463       Gymnorhinus cyanocephalus
#> 464             Cyanocitta stelleri
#> 465                            <NA>
#> 466                            <NA>
#> 467            Aphelocoma insularis
#> 468          Aphelocoma californica
#> 469          Aphelocoma woodhouseii
#> 470                            <NA>
#> 471           Aphelocoma wollweberi
#> 472            Nucifraga columbiana
#> 473                   Pica hudsonia
#> 474                   Pica nuttalli
#> 475                            <NA>
#> 476                 Corvus caurinus
#> 477                            <NA>
#> 478                            <NA>
#> 479                            <NA>
#> 480             Corvus cryptoleucus
#> 481                    Corvus corax
#> 482                            <NA>
#> 483                 Alauda arvensis
#> 484                            <NA>
#> 485                    Progne subis
#> 486             Tachycineta bicolor
#> 487          Tachycineta thalassina
#> 488      Stelgidopteryx serripennis
#> 489                 Riparia riparia
#> 490                            <NA>
#> 491             Petrochelidon fulva
#> 492                            <NA>
#> 493                 Hirundo rustica
#> 494            Poecile carolinensis
#> 495            Poecile atricapillus
#> 496                 Poecile gambeli
#> 497                Poecile sclateri
#> 498               Poecile rufescens
#> 499              Poecile hudsonicus
#> 500                            <NA>
#> 501                            <NA>
#> 502                            <NA>
#> 503                            <NA>
#> 504           Baeolophus wollweberi
#> 505            Baeolophus inornatus
#> 506             Baeolophus ridgwayi
#> 507                            <NA>
#> 508              Baeolophus bicolor
#> 509        Baeolophus atricristatus
#> 510                            <NA>
#> 511             Auriparus flaviceps
#> 512            Psaltriparus minimus
#> 513                            <NA>
#> 514              Sitta carolinensis
#> 515                   Sitta pygmaea
#> 516                   Sitta pusilla
#> 517               Certhia americana
#> 518            Salpinctes obsoletus
#> 519             Catherpes mexicanus
#> 520               Troglodytes aedon
#> 521           Troglodytes pacificus
#> 522            Troglodytes hiemalis
#> 523                            <NA>
#> 524           Cistothorus platensis
#> 525           Cistothorus palustris
#> 526        Thryothorus ludovicianus
#> 527             Thryomanes bewickii
#> 528 Campylorhynchus brunneicapillus
#> 529             Thryophilus sinaloa
#> 530             Polioptila caerulea
#> 531          Polioptila californica
#> 532             Polioptila melanura
#> 533                            <NA>
#> 534               Cinclus mexicanus
#> 535                 Regulus satrapa
#> 536               Regulus calendula
#> 537           Phylloscopus borealis
#> 538                Chamaea fasciata
#> 539                Luscinia svecica
#> 540               Oenanthe oenanthe
#> 541                   Sialia sialis
#> 542                 Sialia mexicana
#> 543              Sialia currucoides
#> 544             Myadestes townsendi
#> 545             Catharus fuscescens
#> 546                Catharus minimus
#> 547              Catharus bicknelli
#> 548              Catharus ustulatus
#> 549               Catharus guttatus
#> 550            Hylocichla mustelina
#> 551                            <NA>
#> 552                 Ixoreus naevius
#> 553          Dumetella carolinensis
#> 554           Toxostoma curvirostre
#> 555                            <NA>
#> 556           Toxostoma longirostre
#> 557              Toxostoma bendirei
#> 558             Toxostoma redivivum
#> 559              Toxostoma lecontei
#> 560              Toxostoma crissale
#> 561            Oreoscoptes montanus
#> 562                Mimus gundlachii
#> 563               Mimus polyglottos
#> 564                Sturnus vulgaris
#> 565            Acridotheres tristis
#> 566             Bombycilla garrulus
#> 567             Bombycilla cedrorum
#> 568                            <NA>
#> 569              Phainopepla nitens
#> 570           Peucedramus taeniatus
#> 571          Euplectes franciscanus
#> 572               Passer domesticus
#> 573                 Passer montanus
#> 574        Motacilla tschutschensis
#> 575                  Motacilla alba
#> 576                 Anthus cervinus
#> 577                Anthus rubescens
#> 578                Anthus spragueii
#> 579         Hesperiphona vespertina
#> 580             Pinicola enucleator
#> 581         Leucosticte tephrocotis
#> 582              Leucosticte atrata
#> 583           Leucosticte australis
#> 584            Haemorhous mexicanus
#> 585            Haemorhous purpureus
#> 586             Haemorhous cassinii
#> 587                            <NA>
#> 588                Acanthis flammea
#> 589             Acanthis hornemanni
#> 590                            <NA>
#> 591               Loxia curvirostra
#> 592                            <NA>
#> 593                Loxia leucoptera
#> 594                            <NA>
#> 595                    Spinus pinus
#> 596                 Spinus psaltria
#> 597                Spinus lawrencei
#> 598                  Spinus tristis
#> 599            Calcarius lapponicus
#> 600               Calcarius ornatus
#> 601                Calcarius pictus
#> 602          Rhynchophanes mccownii
#> 603           Plectrophenax nivalis
#> 604         Arremonops rufivirgatus
#> 605                Pipilo chlorurus
#> 606                Pipilo maculatus
#> 607         Pipilo erythrophthalmus
#> 608                            <NA>
#> 609              Aimophila ruficeps
#> 610                  Melozone fusca
#> 611              Melozone crissalis
#> 612                 Melozone aberti
#> 613                Peucaea carpalis
#> 614                Peucaea botterii
#> 615                Peucaea cassinii
#> 616              Peucaea aestivalis
#> 617            Spizelloides arborea
#> 618              Spizella passerina
#> 619                Spizella pallida
#> 620                Spizella breweri
#> 621                            <NA>
#> 622            Spizella atrogularis
#> 623             Pooecetes gramineus
#> 624                            <NA>
#> 625            Amphispiza bilineata
#> 626       Artemisiospiza nevadensis
#> 627            Artemisiospiza belli
#> 628                            <NA>
#> 629         Calamospiza melanocorys
#> 630                            <NA>
#> 631           Ammodramus savannarum
#> 632              Ammodramus bairdii
#> 633            Ammodramus henslowii
#> 634            Ammodramus leconteii
#> 635              Ammodramus nelsoni
#> 636           Ammodramus caudacutus
#> 637            Ammodramus maritimus
#> 638                            <NA>
#> 639                            <NA>
#> 640             Melospiza lincolnii
#> 641             Melospiza georgiana
#> 642                            <NA>
#> 643             Zonotrichia querula
#> 644                            <NA>
#> 645         Zonotrichia atricapilla
#> 646         Junco hyemalis hyemalis
#> 647         Junco hyemalis oreganus
#> 648          Junco hyemalis mearnsi
#> 649           Junco hyemalis aikeni
#> 650         Junco hyemalis caniceps
#> 651                            <NA>
#> 652                Junco phaeonotus
#> 653                  Icteria virens
#> 654   Xanthocephalus xanthocephalus
#> 655           Dolichonyx oryzivorus
#> 656                 Sturnella magna
#> 657              Sturnella neglecta
#> 658                            <NA>
#> 659                 Icterus spurius
#> 660              Icterus cucullatus
#> 661               Icterus bullockii
#> 662              Icterus pectoralis
#> 663                 Icterus gularis
#> 664             Icterus graduacauda
#> 665                 Icterus galbula
#> 666                            <NA>
#> 667                            <NA>
#> 668               Icterus parisorum
#> 669                            <NA>
#> 670               Agelaius tricolor
#> 671           Molothrus bonariensis
#> 672                Molothrus aeneus
#> 673                            <NA>
#> 674                            <NA>
#> 675              Euphagus carolinus
#> 676          Euphagus cyanocephalus
#> 677                            <NA>
#> 678                            <NA>
#> 679                            <NA>
#> 680                            <NA>
#> 681             Seiurus aurocapilla
#> 682          Helmitheros vermivorum
#> 683              Parkesia motacilla
#> 684         Parkesia noveboracensis
#> 685           Vermivora chrysoptera
#> 686            Vermivora cyanoptera
#> 687                            <NA>
#> 688                            <NA>
#> 689                 Mniotilta varia
#> 690             Protonotaria citrea
#> 691         Limnothlypis swainsonii
#> 692           Leiothlypis peregrina
#> 693              Leiothlypis celata
#> 694              Leiothlypis luciae
#> 695         Leiothlypis ruficapilla
#> 696           Leiothlypis virginiae
#> 697                Oporornis agilis
#> 698              Geothlypis tolmiei
#> 699         Geothlypis philadelphia
#> 700              Geothlypis formosa
#> 701              Geothlypis trichas
#> 702               Setophaga citrina
#> 703             Setophaga ruticilla
#> 704            Setophaga kirtlandii
#> 705               Setophaga tigrina
#> 706               Setophaga cerulea
#> 707             Setophaga americana
#> 708             Setophaga pitiayumi
#> 709              Setophaga magnolia
#> 710              Setophaga castanea
#> 711                 Setophaga fusca
#> 712              Setophaga petechia
#> 713          Setophaga pensylvanica
#> 714               Setophaga striata
#> 715          Setophaga caerulescens
#> 716              Setophaga palmarum
#> 717                 Setophaga pinus
#> 718              Setophaga coronata
#> 719                            <NA>
#> 720              Setophaga coronata
#> 721              Setophaga dominica
#> 722              Setophaga discolor
#> 723               Setophaga graciae
#> 724            Setophaga nigrescens
#> 725             Setophaga townsendi
#> 726          Setophaga occidentalis
#> 727                            <NA>
#> 728                            <NA>
#> 729           Setophaga chrysoparia
#> 730                Setophaga virens
#> 731           Cardellina canadensis
#> 732              Cardellina pusilla
#> 733           Cardellina rubrifrons
#> 734                Myioborus pictus
#> 735                   Piranga flava
#> 736                   Piranga rubra
#> 737                            <NA>
#> 738             Piranga ludoviciana
#> 739                            <NA>
#> 740             Cardinalis sinuatus
#> 741                            <NA>
#> 742         Pheucticus ludovicianus
#> 743       Pheucticus melanocephalus
#> 744              Passerina caerulea
#> 745                Passerina amoena
#> 746                Passerina cyanea
#> 747                            <NA>
#> 748            Passerina versicolor
#> 749                 Passerina ciris
#> 750                 Spiza americana
```

This illustrates that some of our names, e.g. *Dendrocygna bicolor* are
accepted in the Catalogue of Life, while others, *Anser canagicus* are
**known synonyms** of a different accepted name: **Chen canagica**.
Resolving synonyms and accepted names to identifiers helps us avoid the
possible miss-matches we could have when the same species is known by
two different names.

## Taxonomic Data Tables

Local access to taxonomic data tables lets us do much more than look up
names and ids. A family of `by_*` functions in `taxadb` help us work
directly with subsets of the taxonomic data. As we noted above, this can
be useful in resolving certain ambiguous names.

For instance, *Trochalopteron henrici gucenense* does not resolve to an
identifier in ITIS:

``` r
get_ids("Trochalopteron henrici gucenense") 
#> [1] NA
```

Using `by_name()`, we find this is because the name resolves not to zero
matches, but to more than one match:

``` r
by_name("Trochalopteron henrici gucenense") 
#> # A tibble: 1 x 17
#>    sort taxonID scientificName taxonRank acceptedNameUsa… taxonomicStatus
#>   <int> <chr>   <chr>          <chr>     <chr>            <chr>          
#> 1     1 <NA>    <NA>           <NA>      <NA>             <NA>           
#> # … with 11 more variables: update_date <chr>, kingdom <chr>,
#> #   phylum <chr>, class <chr>, order <chr>, family <chr>, genus <chr>,
#> #   specificEpithet <chr>, vernacularName <chr>,
#> #   infraspecificEpithet <chr>, input <chr>
```

``` r
by_name("Trochalopteron henrici gucenense")  %>%
  mutate(acceptedNameUsage = get_names(acceptedNameUsageID)) %>% 
  select(scientificName, taxonomicStatus, acceptedNameUsage, acceptedNameUsageID)
#> # A tibble: 1 x 4
#>   scientificName taxonomicStatus acceptedNameUsage acceptedNameUsageID
#>   <chr>          <chr>           <chr>             <chr>              
#> 1 <NA>           <NA>            <NA>              <NA>
```

Similar functions `by_id`, `by_rank`, and `by_common` take IDs,
scientific ranks, or common names, respectively. Here, we can get
taxonomic data on all bird names in the Catalogue of Life:

``` r
by_rank(name = "Aves", rank = "class", provider = "col")
#> # A tibble: 32,327 x 21
#>     sort taxonID scientificName acceptedNameUsa… taxonomicStatus taxonRank
#>    <int> <chr>   <chr>          <chr>            <chr>           <chr>    
#>  1     1 COL:35… Struthio came… COL:35516814     accepted        species  
#>  2     1 COL:35… Rhea americana COL:35516815     accepted        species  
#>  3     1 COL:35… Dromaius nova… COL:35516817     accepted        species  
#>  4     1 COL:35… Casuarius ben… COL:35516818     accepted        species  
#>  5     1 COL:35… Casuarius una… COL:35516819     accepted        species  
#>  6     1 COL:35… Apteryx austr… COL:35516820     accepted        species  
#>  7     1 COL:35… Tinamus gutta… COL:35516823     accepted        species  
#>  8     1 COL:35… Tinamus major  COL:35516824     accepted        species  
#>  9     1 COL:35… Tinamus osgoo… COL:35516825     accepted        species  
#> 10     1 COL:35… Tinamus solit… COL:35516826     accepted        species  
#> # … with 32,317 more rows, and 15 more variables: kingdom <chr>,
#> #   phylum <chr>, class <chr>, order <chr>, family <chr>, genus <chr>,
#> #   specificEpithet <chr>, infraspecificEpithet <chr>,
#> #   taxonConceptID <chr>, isExtinct <chr>, nameAccordingTo <chr>,
#> #   namePublishedIn <chr>, scientificNameAuthorship <chr>,
#> #   vernacularName <chr>, input <chr>
```

Combining these with `dplyr` functions can make it easy to explore this
data: for instance, which families have the most species?

``` r
by_rank(name = "Aves", rank = "class", provider = "col") %>%
  filter(taxonomicStatus == "accepted", taxonRank=="species") %>% 
  group_by(family) %>%
  count(sort = TRUE) %>% 
  head()
#> # A tibble: 6 x 2
#> # Groups:   family [6]
#>   family           n
#>   <chr>        <int>
#> 1 Tyrannidae     402
#> 2 Psittacidae    377
#> 3 Thraupidae     374
#> 4 Trochilidae    339
#> 5 Columbidae     323
#> 6 Muscicapidae   317
```

## Using the database connection directly

`by_*` functions by default return in-memory data frames. Because they
are filtering functions, they return a subset of the full data which
matches a given query (names, ids, ranks, etc), so the returned
data.frames are smaller than the full record of a naming provider.
Working directly with the SQL connection to the MonetDBLite database
gives us access to all the data. The `taxa_tbl()` function provides this
connection:

``` r
taxa_tbl("col")
#> # Source:   table<dwc_col> [?? x 19]
#> # Database: MonetDBEmbeddedConnection
#>    taxonID scientificName acceptedNameUsa… taxonomicStatus taxonRank
#>    <chr>   <chr>          <chr>            <chr>           <chr>    
#>  1 COL:31… Limacoccus br… COL:316423       accepted        species  
#>  2 COL:31… Coccus bromel… COL:316424       accepted        species  
#>  3 COL:31… Apiomorpha po… COL:316425       accepted        species  
#>  4 COL:31… Eriococcus ch… COL:316441       accepted        species  
#>  5 COL:31… Eriococcus ch… COL:316442       accepted        species  
#>  6 COL:31… Eriococcus ch… COL:316443       accepted        species  
#>  7 COL:31… Eriococcus ci… COL:316444       accepted        species  
#>  8 COL:31… Eriococcus ci… COL:316445       accepted        species  
#>  9 COL:31… Eriococcus bu… COL:316447       accepted        species  
#> 10 COL:31… Eriococcus au… COL:316450       accepted        species  
#> # … with more rows, and 14 more variables: kingdom <chr>, phylum <chr>,
#> #   class <chr>, order <chr>, family <chr>, genus <chr>,
#> #   specificEpithet <chr>, infraspecificEpithet <chr>,
#> #   taxonConceptID <chr>, isExtinct <chr>, nameAccordingTo <chr>,
#> #   namePublishedIn <chr>, scientificNameAuthorship <chr>,
#> #   vernacularName <chr>
```

We can still use most familiar `dplyr` verbs to perform common tasks.
For instance: which species has the most known synonyms?

``` r
most_synonyms <- taxa_tbl("col") %>% 
  group_by(acceptedNameUsageID) %>% 
  count(sort=TRUE)
most_synonyms
#> # Source:     lazy query [?? x 2]
#> # Database:   MonetDBEmbeddedConnection
#> # Groups:     acceptedNameUsageID
#> # Ordered by: desc(n)
#>    acceptedNameUsageID     n
#>    <chr>               <dbl>
#>  1 COL:43082445          456
#>  2 COL:43081989          373
#>  3 COL:43124375          329
#>  4 COL:43353659          328
#>  5 COL:43223150          322
#>  6 COL:43337824          307
#>  7 COL:43124158          302
#>  8 COL:43081973          296
#>  9 COL:43333057          253
#> 10 COL:23162697          252
#> # … with more rows
```

However, unlike the `by_*` functions which return convenient in-memory
tables, this is still a remote connection. This means that direct access
using the `taxa_tbl()` function (or directly accessing the database
connection using `td_connect()`) is more low-level and requires greater
care. For instance, we cannot just add a `%>% mutate(acceptedNameUsage =
get_names(acceptedNameUsageID))` to the above, because `get_names` does
not work on a remote collection. Instead, we would first need to use a
`collect()` to pull the summary table into memory. Users familiar with
remote databases in `dplyr` will find using `taxa_tbl()` directly to be
convenient and fast, while other users may find the `by_*` approach to
be more intuitive.

So which species had those 456 names?

``` r
most_synonyms %>% 
  head(1) %>% 
  pull(acceptedNameUsageID) %>% 
  by_id("col") %>%
  select(scientificName)
#> # A tibble: 1 x 1
#>   scientificName                     
#>   <chr>                              
#> 1 Mentha longifolia subsp. longifolia
```

## Learn more

  - See richer examples the package
    [Tutorial](https://cboettig.github.io/taxadb/articles/intro.html).

  - Learn about the underlying data sources and formats in [Data
    Sources](https://cboettig.github.io/taxadb/articles/articles/data-sources.html)

  - Get better performance by selecting an alternative [database
    backend](https://cboettig.github.io/taxadb/articles/articles/backends.html)
    engines.
