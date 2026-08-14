# Platform Targeting Assessment

## Status

Preliminary working memo for platform selection and geography design. This document combines publicly documented platform behavior with project-specific feasibility judgments. Exact available location targets still need to be checked inside live ad accounts because target inventories vary by country, account context, and privacy thresholds.

## What is documented by the platforms

### Google Ads

Public documentation indicates that Google Ads supports targeting by countries, areas within a country, and radius around a location. Google also states that available location target types vary by country, that radius targeting is not allowed below 1 km, and that location matching is based on multiple signals rather than exact borders.

### Meta Ads

Public documentation indicates that Meta location targeting can reach people in countries, regions, cities, postal codes, and addresses, again using multiple signals rather than exact geographic certainty.

### Practical consequence for this study

Neither platform documentation guarantees that every administrative unit relevant to Spain, Greece, or Bangladesh is targetable at the exact level required for a clean areal-unit randomized design. The final study geography must therefore be chosen from the intersection of:

1. Platform-supported targets.
2. Mosquito Alert reporting geography.
3. Sufficient delivery volume.
4. Administratively meaningful units for analysis.

## Platform recommendation at this stage

### Primary recommendation

Plan around Google Ads and Meta Ads Manager first, not AdMob as the primary experimental assumption.

### Reason

The key design need is explicit control over geographic targeting and campaign structure. That is more directly documented and operationally inspectable in Google Ads and Meta Ads Manager than in an AdMob-centered workflow.

### AdMob note

AdMob may still matter as an inventory or app-promotion channel, but it should not be treated as the first-choice planning anchor for the randomized geography design until its targeting and reporting workflow is validated for this use case.

## Country-by-country assessment

## Spain

### Administrative candidates

1. Autonomous communities.
2. Provinces.
3. Municipalities.

### Feasibility judgment

Spain is the lowest-risk country in the current set for subnational geographic targeting because both major ad platforms are mature there and the administrative geography is stable and well codified.

### Best current planning assumption

Use provinces as the default candidate unit for the main design.

### Why provinces are the current default

1. They are large enough to avoid severe under-delivery in many campaign types.
2. They are likely easier to match consistently across platforms than municipalities.
3. They provide more units than autonomous communities while remaining administratively interpretable.
4. They are more likely than municipalities to support stable aggregate reporting counts.

### Municipality option

Municipalities remain attractive analytically, but should be treated as a second-stage option pending account-level validation because:

1. Inventory may be inconsistent outside larger cities.
2. Delivery volume may be too thin for some units.
3. Platform naming and municipal boundaries may not map cleanly to analytical geography.

### Platform-specific judgment

| Platform | Assessment for Spain | Recommendation |
| --- | --- | --- |
| Google Ads | Strong candidate for province-level targeting; municipality-level targeting must be validated in account | Use for first feasibility audit |
| Meta Ads | Strong candidate for region and city targeting; municipality-level coverage likely uneven outside major urban areas | Use as parallel benchmark |
| AdMob | Do not assume it can be the primary geography-randomization platform without direct testing | Treat as secondary |

### Spain recommendation

Start the design around province-level randomization, then test whether a subset of municipalities can be supported well enough to justify a finer design.

## Greece

### Administrative candidates

1. Regions.
2. Regional units.
3. Municipalities.

### Feasibility judgment

Greece is medium risk for this design. Platforms are likely to support country, region, and major-city targeting, but it is less safe to assume complete and consistent support for regional units or smaller municipalities without account-level checks.

### Best current planning assumption

Use regions as the fallback-safe unit and investigate municipalities in selected urban areas as the preferred finer-grained option.

### Main constraint

Regions may be too coarse for a well-powered randomized design because there are relatively few of them. Municipalities would be analytically better, but only if platform target inventories and delivery volumes are sufficient.

### Platform-specific judgment

| Platform | Assessment for Greece | Recommendation |
| --- | --- | --- |
| Google Ads | Likely workable at country, region, and major city levels; regional-unit support uncertain | Audit region list and city coverage first |
| Meta Ads | Likely workable for regions and cities; municipality coverage needs direct confirmation | Compare city inventory with intended study geography |
| AdMob | High uncertainty for explicit research-grade geography control | Do not use as primary assumption |

### Greece recommendation

Run an early account audit focused on whether the intended municipalities are individually targetable and deliverable. If not, redesign around regions or a smaller, city-focused pilot rather than assuming all municipalities will work.

## Bangladesh

### Administrative candidates

1. Divisions.
2. Districts.
3. Upazilas.
4. Major metropolitan areas or cities.

### Feasibility judgment

Bangladesh is the highest-risk country in the current set for precise geography-based randomization. Country and major-city targeting are likely, but district and especially upazila targeting cannot be assumed from public documentation alone.

### Best current planning assumption

Do not commit yet to district- or upazila-level randomization. Start by testing divisional and major-city coverage, then see whether a district-based design is possible.

### Main constraints

1. Public platform documentation does not guarantee district or subdistrict coverage.
2. Delivery instability is more likely in smaller or less commercially active geographies.
3. Matching platform geography to analytical geography may be harder than in Spain.

### Platform-specific judgment

| Platform | Assessment for Bangladesh | Recommendation |
| --- | --- | --- |
| Google Ads | Likely reliable at country and major-city level; district support uncertain and must be tested | Audit district availability directly in account |
| Meta Ads | Likely usable for country and major-city targeting; finer administrative support uncertain | Check city and region inventory before design lock |
| AdMob | Not suitable as the planning default for a district-randomized design without direct proof of support | Avoid as primary platform |

### Bangladesh recommendation

Treat Bangladesh as a separate feasibility track. If district-level targeting proves weak or inconsistent, a full three-country design using a common administrative level may not be realistic. In that case, either:

1. Use country-specific geography levels with country-specific analyses.
2. Pilot Bangladesh separately.
3. Exclude Bangladesh from the first experimental wave until targeting and data export are confirmed.

## Cross-country platform comparison

| Country | Safest likely unit now | More ambitious unit worth testing | Overall platform risk |
| --- | --- | --- | --- |
| Spain | Province | Municipality | Low to medium |
| Greece | Region | Municipality | Medium |
| Bangladesh | Division or major city | District | High |

## Design implications for the study

1. A single common areal-unit level across all three countries may be unrealistic.
2. The ethics and protocol documents should describe geography selection as contingent on platform feasibility rather than pre-committing to municipalities.
3. Randomization should be implemented only after a documented target-inventory audit is saved for each platform and country.
4. Delivery optimization settings must be reviewed carefully so they do not undermine the intended geographic assignment logic.

## Immediate next checks inside ad accounts

1. Export or manually record the available target list for candidate geographies in Spain, Greece, and Bangladesh.
2. Verify whether the platforms expose provinces, regions, districts, municipalities, or only cities and radii.
3. Check whether campaign reporting can be retrieved by geography in a way that matches the randomization plan.
4. Check whether age-targeting controls can reduce incidental minor exposure for ethics purposes.
5. Run budget and delivery simulations for a small sample of candidate units.

## Provisional platform decision

If the team wants the fastest route to a defendable first protocol, the cleanest current position is:

1. Build the ethics and study plan around Google Ads and Meta as the primary candidate platforms.
2. Use province-level planning for Spain.
3. Keep Greece and Bangladesh explicitly conditional on account-level target audits.
4. Treat AdMob as a possible supplementary channel, not the design anchor.
