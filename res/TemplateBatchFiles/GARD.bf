/**
*   ---- OUTLINE ----
*   1. SETUP
*       1a. Initial Setup
*       1b. User Input
*       1c. Load and Filter Data
*       1d. Checks
*   2. MAIN ANALYSIS
*       2a. Fit on entire alignment
*           2a-1. Infer NJ tree estimting rate parameters (branch-lengths, frequencies and substitution rate matrix)
*           2a-2. Optain AIC score
*       2b. Evaluation of single break points with brute force
*       2c. Evaluation of multiple break points with genetic algorithm
*   3. POST PROCESSING
*
*   GARD FUNCTIONS
*/

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    1. SETUP
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/


/*------------------------------------------------------------------------------
    1a. Initial Setup
*/
LoadFunctionLibrary ("libv3/tasks/trees.bf");
LoadFunctionLibrary ("libv3/tasks/alignments.bf");
LoadFunctionLibrary ("libv3/tasks/estimators.bf");
LoadFunctionLibrary ("libv3/convenience/regexp.bf");
LoadFunctionLibrary ("libv3/convenience/math.bf");
LoadFunctionLibrary ("libv3/IOFunctions.bf");
LoadFunctionLibrary ("libv3/UtilityFunctions.bf");


gard.analysis_description = {terms.io.info : "GARD : Genetic Algorithms for Recombination Detection. Implements a heuristic
approach to screening alignments of sequences for recombination, by using the CHC genetic algorithm to search for phylogenetic
incongruence among different partitions of the data. The number of partitions is determined using a step-up procedure, while the
placement of breakpoints is searched for with the GA. The best fitting model (based on c-AIC) is returned; and additional post-hoc
tests run to distinguish topological incongruence from rate-variation.",
                           terms.io.version : "0.1",
                           terms.io.reference : "**Automated Phylogenetic Detection of Recombination Using a Genetic Algorithm**, _Mol Biol Evol 23(10), 1891–1901",
                           terms.io.authors : "Sergei L Kosakovsky Pond",
                           terms.io.contact : "spond@temple.edu",
                           terms.io.requirements : "A sequence alignment."
                          };


namespace terms.gard {
    nucleotide = "Nucleotide";
    protein    = "Protein";
    codon      = "Codon";
};

namespace gard.parameters {

};

gard.master_list = {}; // "model string" -> "model fitness"


/*------------------------------------------------------------------------------
    1b. User Input
*/
io.DisplayAnalysisBanner (gard.analysis_description);

KeywordArgument ("type",        "The type of data to perform screening on", "Nucleotide");
KeywordArgument ("code",        "Genetic code to use (for codon alignments)", "Universal", "Choose Genetic Code");
KeywordArgument ("alignment",   "Sequence alignment to screen for recombination");

gard.data_type = io.SelectAnOption  ({terms.gard.nucleotide : "A nucleotide (DNA/RNA) alignment",
                                      terms.gard.protein : "A protein alignment",
                                      terms.gard.codon : "An in-frame codon alignment"},
                                      "The type of data to perform screening on");


/*------------------------------------------------------------------------------
    1c. Load and Filter Data
*/
if (gard.data_type == terms.gard.nucleotide) {
    LoadFunctionLibrary ("libv3/models/DNA/GTR.bf");
    gard.model.generator = "models.DNA.GTR.ModelDescription";
    gard.alignment = alignments.ReadNucleotideDataSet ("gard.sequences", null);
    DataSetFilter gard.filter = CreateFilter (gard.sequences, 1);
} else { 
    // TODO: implement these branches
    if (gard.data_type == terms.gard.protein) {
        gard.alignment = alignments.ReadProteinDataSet ("gard.sequences", null);
        DataSetFilter gard.filter = CreateFilter (gard.sequences, 1);
    } else {
        gard.alignment = alignments.LoadGeneticCodeAndAlignment ("gard.sequences", "gard.filter", null);
    }
}


/*------------------------------------------------------------------------------
    1d. Checks
*/

// Too few sites for c-AIC inference.


/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    2. MAIN ANALYSIS
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

// WORKING SECTION
gard.model = model.generic.DefineModel (gard.model.generator, "gard.overall_model", {"0" : "terms.global"}, "gard.filter", null); 
 
console.log (gard.fit_partitioned_model ({{100,200,300}}, gard.model, null)); 

/*------------------------------------------------------------------------------
    2a. Fit on entire alignment
*/

// 2a-1. Infer NJ tree estimting rate parameters (branch-lengths, frequencies and substitution rate matrix)

// 2a-2. Optain AIC score

/*------------------------------------------------------------------------------
    2b. Evaluation of single break points with brute force
*/


/*------------------------------------------------------------------------------
    2c. Evaluation of multiple break points with genetic algorithm
*/


/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    3. POST PROCESSING
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

//--------------------------------------------------------------------------------------------------------------------

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    GARD FUNCTIONS
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/**
 * @name tgard.fit_partitioned_model
 * Given a list of partitions, specified as increasing breakpoint locations,
   fit the specified model to said partitions, using neighbor joining trees on each partition
   return LogL and IC values
   
 * @param {Matrix} breakPoints : sorted, 0-based breakpoints, e.g.
    {{100,200}} -> 3 partitions : 0-100, 101-200, 201-end
 * @param {Dict} model : an instantiated model to be used for all partitions
 * @param {Dict/null} initial_values : if provided, use as initial values
    
 * @returns a {Dictionary} :
    terms.fit.log_likelihood -> log likelihood
    terms.fit.AICc -> small sample AIC

 */
 
lfunction gard.fit_partitioned_model (breakPoints, model, initial_values) {

    current_index = 0;
    current_start = 0;
    breakPoints_count = utility.Array1D (breakPoints);
    part_count = breakPoints_count + 1;
    lf_components = {2 * (part_count), 1};
    trees = {};
            
    for (p = 0; p < part_count; p += 1) {
        last_partition = p >= breakPoints_count;
        if (!last_partition) {
            current_end = breakPoints[p];
        } else {
            current_end = ^"gard.filter.sites" - 1;
        }
        lf_components [2*p] = "gard.filter.part_" + p;
        lf_components [2*p+1] = "gard.tree.part_" + p;
        DataSetFilter ^(lf_components[2*p]) = CreateFilter (^"gard.filter", 1, "" + current_start + "-" + current_end);
        trees[p] = trees.ExtractTreeInfo (tree.infer.NJ ( lf_components[2*p], null));
        model.ApplyModelToTree(lf_components[2 * p + 1], trees[p], {
            "default": model
        }, None);
        // Increment the current starting point
        if (!last_partition) {
            current_start = breakPoints[p];
        }
    }

    lf_id = &likelihoodFunction;
    utility.ExecuteInGlobalNamespace ("LikelihoodFunction `lf_id` = (`&lf_components`)");
    
    model_objects = {
        "gard.overall_model" : model
    };
    
    df = 0;
    if (Type(initial_values) == "AssociativeList") {
        utility.ToggleEnvVariable("USE_LAST_RESULTS", 1);
        df = estimators.ApplyExistingEstimates(&likelihoodFunction, model_objects, initial_values, None);
    }
    
    return estimators.FitExistingLF (&likelihoodFunction, model_objects);    
}
