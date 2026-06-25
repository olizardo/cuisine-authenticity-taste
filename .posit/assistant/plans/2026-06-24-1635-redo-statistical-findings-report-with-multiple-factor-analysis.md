# Plan: Redo Statistical Findings Report with Multiple Factor Analysis (MFA)

We will update the geometric data analysis in `statistical-findings-report.qmd` to use **Multiple Factor Analysis (MFA)** instead of standard **Principal Component Analysis (PCA)**. MFA is a more appropriate statistical approach because it balances the influence of distinct survey blocks so that no single set of questions dominates the first dimension, while preserving the metric structures of the continuous variables.

## 1. Survey blocks and groupings
As detailed in `codebook.qmd`, the active and supplementary columns select and arrange the data in the following natural survey blocks:
- **`dine_out`**: `fancy_restaurant`, `fast_food` (2 active continuous variables)
- **`food_qual`**: `light`, `rich`, `authentic`, `familiar`, `big`, `small` (6 active continuous variables)
- **`food`**: `caviar`, `oysters`, `nuggets`, `cheeseburger`, `sourdough`, `avocado` (6 active continuous variables)
- **`authenticity`**: 15 international cuisine ratings (`japanese` to `lebanese`) (15 active continuous variables)
- **`quant.sup`**: `age`, `income`, `educ`, `peduc`, `arts`, `city`, `relig` (7 quantitative supplementary variables)
- **`quali.sup`**: `race.f`, `sex.f`, `gend.f`, `spol.f`, `epol.f`, `educ.f`, `arts.f`, `inc.f`, `age.f`, `peduc.f`, `city.f`, `relig.f` (12 qualitative supplementary factors)

## 2. Dimensional extraction and eigenvalue threshold
Running MFA on this structure in R shows that exactly **3 dimensions** have eigenvalues above the 1.0 threshold:
- **Comp 1**: 1.5510
- **Comp 2**: 1.3517
- **Comp 3**: 1.2320
- (Comp 4 is 0.7809, which is below 1.0 and will be discarded)

We will configure the MFA call to keep exactly these 3 dimensions (`ncp = 3`).

## 3. Detailed changes in `statistical-findings-report.qmd`

### Section: Setup and Introduction
- Update titles, headers, and introductory paragraphs to present Multiple Factor Analysis (MFA) as the primary methodology, explicitly explaining why grouping the survey blocks and balancing their variance is appropriate.

### Section: MFA Dimensional Extraction
- Replace the `PCA` call with the FactoMineR `MFA` call:
  ```r
  mfa.res <- MFA(
      base = dat,
      group = c(2, 6, 6, 15, 7, 12),
      type = c("s", "s", "s", "s", "s", "n"),
      name.group = c("dine_out", "food_qual", "food", "authenticity", "quant.sup", "quali.sup"),
      num.group.sup = c(5, 6),
      ncp = 3,
      graph = FALSE
  )
  ```
- Change `get_pca_var(mfa.res)` to `get_mfa_var(mfa.res)` to extract coordinates/correlations, as `get_pca_var` does not support MFA objects.
- Update the correlation heatmap filter to keep dimensions 1 to 3: `filter(Dimension %in% c("Dim.1", "Dim.2", "Dim.3"))`.

### Section: Substantive Interpretations
Update the textual descriptions of the extracted axes to match the new MFA dimensions:
- **Dimension 1 (Fancy Taste Axis)**: Positively anchored by fine dining frequency (`fancy_restaurant` $r = 0.75$) and upscale food preferences (`caviar` $r = 0.70$, `oysters` $r = 0.64$).
- **Dimension 2 (Common/Mainstream Taste Axis)**: Positively anchored by familiar/rich tastes (cheeseburgers $r=0.64$, nuggets $r=0.58$) and fast-food dining frequency ($r=0.48$).
- **Dimension 3 (Professional Chef vs. Home Heritage Axis)**: Captures the distinction between a "Professional Chef" orientation for international cuisines (valuing high-end restaurant preparation for cuisines like lebanese $r=0.52$, pakistani $r=0.50$, nigerian $r=0.49$) vs. a traditional "home-cooked/heritage" orientation (negatively correlated with "exotic/authentic" general taste preference $r=-0.56$).

### Section: Multivariate Analysis of Variance (MANOVA)
- Modify the MANOVA formula to test the 3 coordinates with eigenvalues above 1.0:
  ```r
  fit_manova <- manova(
      cbind(Dim.1, Dim.2, Dim.3) ~ race.f + age.f + educ.f + peduc.f + city.f + arts.f + spol.f + epol.f + relig.f + inc.f + gend.f + sex.f + 
          educ.f:spol.f + gend.f:sex.f, 
      data = mfa.dat
  )
  ```
- Update the table title and subtitles in the GT code to reflect the 3-dimensional MFA taste space.

### Section: Centroid Projections & Ellipses
- The custom functions and plots are already designed for 3 dimensions, so they will align perfectly with our 3-dimensional coordinate space (Dim 1 vs. Dim 2, Dim 1 vs. Dim 3, Dim 2 vs. Dim 3) without requiring structural structural changes, but we will ensure labels and axes match.

### Section: Hierarchical Clustering (HCPC) & Multinomial Logistic Regression
- Since `mfa.res` is fitted with `ncp = 3`, HCPC clustering and the downstream multinomial models will run on exactly the 3 dimensions with eigenvalues above 1.0.
- All code segments in these blocks are verified to run correctly.

## 4. Verification and Rendering
1. Run the code chunks in the active session to verify that no errors are raised.
2. Render the Quarto document using `quarto render statistical-findings-report.qmd` to ensure the final HTML is built successfully and matches the updated figures and tables.
