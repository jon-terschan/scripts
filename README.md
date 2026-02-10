# HELMI - Helsinki Microclimate Index: A predictive machine-learning model of Summer near-ground temperatures in Helsinki parks and urban forests

A short summary of the model, performance metrics and limitations. Helmi's target domain is urban parks and forests. High-performance computing (HPC), in particular CSC's Puhti supercomputer (decommissioned in Spring 2026) was used to process airborne laser scanning (ALS) tiles and for model training, tuning, and predictions.

## Performance

Performance overview.

## Limitations

Limitations overview.

## Future improvements

* Change model to XGBoost
* Incorporate detailed cloud information (e.g., hourly METEOSAT cloud masks) into the model.
* Add more ERA5-Land fields (radiation flow, wind) as dynamic predictors.  

## Acknowledgements

This publication builds on many excellent open-source software, packages and libraries. Many thanks to the authors and maintainers who make this work possible. ❤️
We also want to acknowledge the computational resources contributed by CSC here. See [CREDITS.md](CREDITS.md) for details.

For acknowledgements related to the research in which Helmi was published and the connectivity analysis, please check out the corresponding publication.

## Citation

If you use HELMI in academic work, please cite the associated publication and the model:

**Primary reference**  
Terschanski, J. (Year). *Title of the article*. Journal Name. DOI

**Model**  
Terschanski, J. (2026). *HELMI — Helsinki Microclimate Index* (Version 0.0.1).  
GitHub repository: https://github.com/jon-terschan/helsinki-microclimate-index  
DOI: ENTER DOI WHEN READY

## BibTex

---

## Technical documentation

* [Airborne laser scanning derived metrics](/documentation/ALS_PROCESSING.md)
* [Other static predictors](/documentation/STATIC_VARIABLES.md)
* [Dynamic predictors](/documentation/DYNAMIC_VARIABLES.md)
* [Modeling](/documentation/MODELING.md)