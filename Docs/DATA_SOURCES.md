# Data sources and verification log

Rule: a species is `verified: true` only when every filled field was checked against a page we actually read.
Anything we could not read stays empty and the card shows an "Unverified" tag.
Last checked: 29 Oct 2026.

## Verified (2 of 5 seeded)

| Species | Fields confirmed | Source read |
|---|---|---|
| Magnetic termite (*Amitermes meridionalis*) | Name, family Termitidae, order Blattodea ([ALA/AFD](https://bie.ala.org.au/species/Magnetic+Termite%2C+Compass+Termite)). Mound is 3 to 4 m tall, about 3 m east-west and about 1 m north-south, with the alignment shielding the nest from summer sun ([Australian Museum](https://australian.museum/learn/animals/insects/termites/)). | Both pages opened. |
| Leichhardt's grasshopper (*Petasida ephippigera*) | Name, family Pyrgomorphidae, order Orthoptera ([ALA/AFD](https://bie.ala.org.au/species/Leichhardt's+Grasshopper)). Habitat, host plants (Pityrodia), 1845 colour description, no records until 1971 ([ALA blog](https://www.ala.org.au/blogs-news/first-ala-records-of-elusive-leichhardts-grasshopper-in-arnhem-land/)). | Both pages opened. |

`isSensitive` is true for Leichhardt's grasshopper as a cautious app choice (the ALA blog describes it as near-threatened and sparsely distributed). It is not a conservation rating we are publishing.

## Unverified (3 of 5): what is missing

| Species | What we know | What is missing |
|---|---|---|
| Green tree ant (*Oecophylla smaragdina*) | Name, family Formicidae, order Hymenoptera confirmed on [ALA](https://bie.ala.org.au/species/Oecophylla+smaragdina). | **Check by hand:** the NT Government fact sheet ([greenants.pdf](https://nt.gov.au/__data/assets/pdf_file/0009/199998/greenants.pdf)) returned 403 to our tools. A search summary says nests are leaves stitched with larval silk, but we have not read the page. No fun fact entered. |
| Cathedral termite (*Nasutitermes triodiae*) | ALA lists the species as "Spinifex Termite" (search result title only; page returned 404). | **Check by hand:** [termite-homes.pdf](https://nt.gov.au/__data/assets/pdf_file/0003/200001/termite-homes.pdf) (403). Family, order and facts left empty. "Cathedral termite" is the common name from our brief. |
| Common crow (*Euploea corinna*) | [ALA](https://bie.ala.org.au/species/Euploea+core) treats *Euploea core* as a synonym of *E. corinna* (accepted name "Oleander Butterfly", "Common Crow" is a preferred vernacular). Family Nymphalidae, order Lepidoptera. | The ALA page has no description or distribution. We have not confirmed it occurs in the NT. Other databases may still use *E. core*. |

## Dropped
Meat ant (*Iridomyrmex purpureus*) was removed from the seed on 29 Oct 2026. ALA lists the common name as "Southern Meat Ant" and we could not confirm it occurs in the NT. It can come back if someone verifies NT presence from a page we can read.

## Insect orders (order-level answers)
`InsectOrder` in TrailCore lists nine orders (Coleoptera, Lepidoptera, Hymenoptera, Blattodea, Orthoptera, Hemiptera, Odonata, Diptera, Mantodea) with plain-English group names. This is standard taxonomy, not an NT claim, and is only used so people can answer "I only know the group". Termites sit inside Blattodea.

## Vision labels (Tier 1 hint)
The label list was dumped from Apple's Vision `VNClassifyImageRequest` (revision 2, 1303 labels, run on macOS 29 Oct 2026). The insect-related labels that actually exist are: ant, bee, butterfly, dragonfly, insect, ladybug, moth (plus spider, which is not an insect). There is no label for beetle, grasshopper, termite, wasp or fly, so those are never suggested. The app re-checks `supportedIdentifiers()` at run time. This list has not been re-dumped on an iPhone.

## Not yet researched
About 19 more species are needed to reach the ~25 target. None are in `species.json` yet.

## Indigenous knowledge
No Aboriginal names, stories or bush-tucker claims are included. ALA lists Indigenous names for some species; we deliberately did not copy them.
Placeholder shown in-app: "Traditional knowledge: to be added with community guidance."

## Images
Silhouettes only (original SwiftUI shapes). No species photos are bundled, so `photoCredit` is null.
