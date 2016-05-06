LoadFunctionLibrary("libv3/IOFunctions.bf");

function test_reportStatsMD () {
    absrel.stats = {
     "Count":4,
     "Mean":2.25,
     "Median":2,
     "Min":1,
     "Max":4,
     "2.5%":1,
     "97.5%":4,
     "Sum":9,
     "Std.Dev":1.089724735885168,
     "Variance":1.1875,
     "COV":0.4843221048378527,
     "Skewness":0.6520236646847543,
     "Kurtosis":2.096952908587257,
     "Sq. sum":18,
     "Non-negative":4
    };
    io.reportStatsMD("aBSREL", absrel.stats);
}


function test_parse_json() {
    file_path = "./data/CD4.old.out.json";
    parsed_json = io.parse_json(file_path);
    fprintf(stdout, parsed_json);
}

test_parse_json();
