# PodDisruptionBudgetAtLimit
Some applications will deploy with a `PodDisruptionBudget` to ensure that an application always has its minimum amount of Pods which prevents some cluster activities from draining nodes if the configured replicas aren't met. This is a great idea, but there are times where some applications may have this misconfigured when deployed and can prevent cluster maintenance from occuring. As there is an Alert that gets triggered when a `PodDisruptionBudget` is at a point where its minimum available is equal to what is currently running, we can use this to identify workloads that may need to be modified to allow standard cluster operations.

Due to the nature of modifying such an object because of its intended nature, it may be best to put some checks in place on this. A few checks that could be done would be to ensure the application's `Deployment` has a certain number of replicas configured or even check into if there are `Pods` that are crashing.

*NOTE:* Alert does not appear to be present in HCP clusters, but for all other clusters, this can be a valuable thing.
