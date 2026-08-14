# Study Plan Draft

## Working title

IDAlert T5.4 Areal-Unit-Based Motivation Study

## Draft status

This is a working draft intended to guide project setup, ethics preparation, and implementation planning. It should be revised after confirming platform targeting constraints, campaign budget, and available reporting data from Mosquito Alert.

## Background

Mosquito Alert is a citizen science system that depends on voluntary reporting. This study will test whether geographically targeted advertising that uses different motivational framings can increase reporting activity in selected areal units. Messaging will be based on regulatory focus framing described in the target literature, with at least one neutral comparison condition.

The current design assumption is that ad content can be randomized at the level of an areal unit, such as a province or municipality, and that outcomes can be analyzed using aggregate counts of reports before and after campaign launch.

## Primary objective

Estimate whether motivationally framed digital ads increase the volume of Mosquito Alert reports relative to neutral messaging and to pre-campaign baseline levels.

## Secondary objectives

1. Compare the relative performance of promotion-focused, prevention-focused, and neutral ad messaging.
2. Assess whether effects differ across countries and administrative levels.
3. Evaluate feasibility of running a reproducible, ethics-cleared, geographically randomized ad intervention using only aggregate analysis outputs.

## Proposed study settings

The initial implementation scope includes:

1. Spain
2. Greece
3. Bangladesh

For each country, the final study geography must be chosen only after confirming which administrative levels can be targeted on the selected ad platform. The working rule should be to use the smallest administrative unit that meets all of the following conditions:

1. Available as a targetable geography on the ad platform.
2. Large enough to support campaign delivery without extreme under-delivery.
3. Large enough to yield stable post-period reporting counts.
4. Compatible with data aggregation from the Mosquito Alert system.

## Intervention concept

Each eligible areal unit will be assigned to one ad condition.

### Candidate conditions

1. Promotion-focused framing.
2. Prevention-focused framing.
3. Neutral informational framing.

### Intervention components

1. Static or responsive display ads.
2. Localized language where appropriate.
3. Landing flow pointing to Mosquito Alert download or reporting pathways.
4. Standardized visual identity as far as possible across conditions.

### Randomization unit

Primary plan: areal unit.

If platform constraints make clean geographic randomization impossible at the desired level, the fallback options should be assessed in this order:

1. Larger areal units with explicit stratification.
2. Time-staggered rollout by geography.
3. Platform change if another ad system offers cleaner location targeting.

## Key feasibility checks

### Ad platform assessment

Before locking the protocol, confirm:

1. Which platforms allow targeting by province, municipality, district, or equivalent in each country.
2. Whether campaign-level randomization can be mapped cleanly to geography.
3. Whether reporting exports can provide aggregate counts by the same geography and time interval.
4. Whether the platform provides any audience categories or optimization features that would undermine the intended randomization and need to be disabled.

### Data availability check

Confirm with the Mosquito Alert data team:

1. Available outcome variables.
2. Historical baseline coverage period.
3. Expected lag between report submission and export availability.
4. Whether aggregate counts can be generated without exposing personal or device-level identifiers.

## Outcomes

## Primary outcome

Count of Mosquito Alert reports per areal unit per fixed time interval.

## Candidate secondary outcomes

1. First-time reports, if available only in aggregate form.
2. App downloads or registrations by geography, if accessible in aggregate form.
3. Cost per incremental report.

## Study periods

Working assumption:

1. Pre-period baseline: 8 to 12 weeks.
2. Campaign period: 4 to 8 weeks.
3. Post-period follow-up: 2 to 4 weeks.

Final durations should be chosen with seasonal mosquito activity and budget constraints in mind.

## Analysis approach

### Core design

Difference-in-differences style analysis using panel data at the areal-unit-by-time level.

### Planned model components

1. Areal unit fixed effects.
2. Time fixed effects.
3. Condition indicators and condition-by-post interactions.
4. Country indicators or country-specific models.
5. Cluster-robust uncertainty at the areal-unit level where feasible.

### Sensitivity analyses

1. Exclude areal units with very low baseline volume.
2. Use alternative time aggregation windows.
3. Test event-study style specifications if enough periods are available.
4. Check robustness to campaign delivery intensity if delivery differs materially across geographies.

## Operational workflow

1. Finalize literature review and messaging rationale.
2. Confirm targeting capabilities and candidate geographies.
3. Produce ad copy and translations.
4. Draft ethics submission and complete institutional templates.
5. Build data extraction scripts.
6. Launch pilot in one country if feasible.
7. Run full campaigns.
8. Analyze and report results.

## Roles to assign

1. Principal investigator and ethics lead.
2. Country implementation lead.
3. Ad operations lead.
4. Data engineering lead.
5. Analysis lead.
6. Documentation and reporting lead.

## Immediate unresolved decisions

1. Exact ad platform or platform mix.
2. Smallest viable geographic targeting unit by country.
3. Whether download, registration, and report outcomes are all available in aggregate form.
4. Final number of study arms and budget per arm.
5. Whether seasonal timing differs enough across countries to require country-specific schedules.

## Near-term deliverables

1. Platform targeting memo covering Spain, Greece, and Bangladesh.
2. Messaging matrix with draft copy by condition and language.
3. Ethics application checklist draft.
4. Data schema for areal-unit-by-period outcomes.
5. Analysis scripts in R and Python for reproducible aggregation and modeling.
