import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression,LogisticRegressionCV
import pymc3 as pm
import theano.tensor as tt
from theano import shared
from sklearn.model_selection import train_test_split,cross_val_score, GridSearchCV, StratifiedKFold,GroupKFold,RandomizedSearchCV
from sklearn.ensemble import RandomForestClassifier
import sklearn.preprocessing as prepro
from sklearn.neighbors import KNeighborsClassifier
import sklearn.metrics as metrics
import copy
#from sksom import SKSOM
#import xgboost as xgb





def splithypothesis(*args,cvgenerator,xset,model_cv,number_of_splits,number_of_folds,yset,ygroup,ygroup2):
    """
    Tests the splits hypothesis on the LogisticRegression classifier.
    
    Input:
    cvgenerator: A cross-validator that can split data into folds
    xset: The features that will be used on the classifier
    model_cv: A function that will perform the cross-validation and select the hyperparameters
              of the classifier based on its performance on the cvgenerators folds
              examples are log_cv and rfr_cv
    number_of_splits: Number of ways to split the data into train-test
    number_of_folds: Number of ways to split the train set into validation sets
    yset: Labels of data, must match length of xset
    Output:
    scoring_results: A list of the accuracy of the classifier on each test fold
    best_parameters: A list of parameters used by the classifier to calculate the score for each test fold
    coefficients: A list of arrays with the iportance of the features
    """
    np.random.seed(11235)
    traintestsplit  = cvgenerator(n_splits=number_of_splits)
    # try:
    # 	grouppings =args[0]["group"]
    # except KeyError:
    # 	grouppings = None
    # 	print("No groupping parameters")
    # Storing Index
    yindex = yset.index
    Ksets = traintestsplit.split(xset,y =ygroup,groups=ygroup)
    # scoring_results is a list with the scores of the estimator on each test set in
    # the traintestsplit folds.
    best_parameters =[]
    scoring_results = []
    coefficients =[]
    false_samples =[]
    confusion = np.zeros((np.unique(yset).shape[0],np.unique(yset).shape[0]))
    # Vlidation cross vlidator
    try:
    	cvgenerator2 = args[0]["cvgenerator2"]
    except KeyError:
    	print("Same CV generator as train-test split. To change it set cvgenerator2 to StratifiedKFold or GroupKFold")
    	cvgenerator2 = cvgenerator
    for i,index in enumerate( Ksets):
        train_index,test_index = index
        xtrain,xtest = xset.iloc[train_index],xset.iloc[test_index]
        ytrain,ytest = yset.iloc[train_index],yset.iloc[test_index]
        set_for_kfold = ygroup2.loc[xtrain.index]
        print(i)
        np.random.seed(11235)

        # Try scaling. The if a scaler is not provided then the identity transformation is used instead
        try:
            scaler = args[0]["scaler"].fit(xtrain)
        except (KeyError,AttributeError):
            print("The identity scaler is used. To change it pass a preprocessing class ",
            "with the variable scaler")
            scaler = prepro.FunctionTransformer(validate = False).fit(xtrain)
        # Applying the transformation on the train set
        xtrain =scaler.transform(xtrain)

        CVfolds = cvgenerator2(n_splits = number_of_folds)
        Kfolds = CVfolds.split(xtrain,y = set_for_kfold,groups=set_for_kfold)
#         for ind1,ind2 in Kfolds:
#             print(set_for_kfold.iloc[ind2])
        # Perform grid CV using Kfolds as folds.
        parameters,CVgrid,coef =model_cv(args[0],X=xtrain,y = ytrain,trainfolds=Kfolds)
        # Transform our test data using the same scaler as the train
        xtest = scaler.transform(xtest)
        predicted = CVgrid.predict(xtest)
        # parameters are the best parameters of the model and CVgrid is the output
        # of the GridSearchCV method
        conf_matrix = metrics.confusion_matrix(ytest, predicted)
        
        best_parameters.append(parameters)
        scoring_results.append( metrics.accuracy_score(ytest,predicted ))
        coefficients.append(coef)
        if conf_matrix.shape == (1,1):
            if all(ytest ==0) or all(ytest == "Black"):
                conf_matrix = np.array([[conf_matrix.item(),0],[0,0]])
            else:
                conf_matrix = np.array([[0,0],[0,conf_matrix.item()]])
        print(conf_matrix)
        confusion += conf_matrix

        # Checking which samples where wrongly predicted
        false_samples +=yindex[test_index[ytest != predicted]].tolist()
    return(scoring_results,best_parameters,coefficients,confusion,false_samples)

def runningsplittest(foldgenerator,model_cv,index,xsetlist,ysetlist,number_of_splits=7,number_of_folds=6,**kwargs):
    """
    Input
    foldgenerator: Stratified or Group KFold
    model_cv: The model CV to use, log_cv or rfr_cv
    
    """
    dictr ={"Scores":[],"Parameters":[],"Coefficients":[],"Confusion":[],"FalseSamples":[]}
    if index ==None:
        index = ["OTU","OTU CSS","OTU MIN CSS","PCoA","PCoA CSS"]
        xsetlist = [otudf,otudfCss,otudfMinCss,pcoaOtu,pcoaCss]
        ysetlist =[wwfdf,wwfdf,wwfdfmin,wwfdf,wwfdf]

    # Setting group variable used for the stratified or group split of 
    # train-test split and for validation fold splits. If not set as kwarg
    # the response variable is used, This amounts to the usual stratified 
    # sampling
    try:
    	ygrouplist = kwargs["ygrouplist"]
    except KeyError:
        print("Using class labels as groupping variables. To choose a different groupping ",
        " set pass a list of the variables to groupby. Pass the list to ygrouplist")
        ygrouplist = ysetlist
    try:
    	ygrouplist2 = kwargs["ygrouplist2"]
    except KeyError:
        print("Using the same groupping svariable in the validation split")
        ygrouplist2 = ygrouplist
    for i,j in enumerate(index):
        print(i)
        # Running the hypothesis for all cases in the index
        scoring,best_parameters,coefficents,confusion,falsesamples =splithypothesis(kwargs,cvgenerator=foldgenerator,xset=xsetlist[i],model_cv=model_cv,
                                number_of_splits=number_of_splits,number_of_folds=number_of_folds ,yset=ysetlist[i],ygroup = ygrouplist[i],
                                ygroup2 = ygrouplist2[i])

        dictr["Scores"]+=[scoring]
        dictr["Parameters"] += [best_parameters]
        dictr["Coefficients"] += [coefficents]
        dictr["Confusion"] += [confusion]
        dictr["FalseSamples"] += [falsesamples]
    dataf =pd.DataFrame(data = dictr,index=index)
    return(dataf)


def log_cv(*args,X, y,trainfolds):
    """
    Function performs Grid search Cross validation with trainfolds as folds generator. 
    Inputs:
    X: Train set
    y: Test set 
    trainfolds: CV folds generator
    Returns:
    best_params: Best parameters of the CV procedure
    grid_result: The output of the GridSearchCV method when fitted to
                 X and y
    """
    try:
        penalty = args[0]["penalty"]
    except KeyError:
        penalty = "l1"
        print("You haven't specified a penalty, we will be using l1. Pass your desired penalty",
       " to the variable penalty")
    if trainfolds ==None:
        foldscv = StratifiedKFold(n_splits=5,random_state=11235)
        trainfolds =foldscv.split(X,wwfdf.Area_group.loc[X.index])
    gsc = GridSearchCV(
    estimator=LogisticRegression(penalty=penalty,solver='liblinear',max_iter=1000,random_state=11235,fit_intercept=True),
        param_grid={
            'C': [0.0001,0.001,0.01,0.1,1,20,50] + list(np.arange(2,20,1))
           
            #,'fit_intercept': (True)
        },
        cv=trainfolds, scoring = ["accuracy"], verbose=1, n_jobs=-1,refit = "accuracy",
        return_train_score = False
)
    
    grid_result = gsc.fit(X, y)
    best_params = grid_result.best_params_
    coefficients =grid_result.best_estimator_.coef_
    #rfr = RandomForestRegressor(max_depth=best_params["max_depth"], n_estimators=best_params["n_estimators"],random_state=False, verbose=False)
    # Perform K-Fold CV
    #scores = cross_val_score(rfr, X, y, cv=10, scoring='neg_mean_absolute_error')

    return best_params,grid_result,coefficients


def rfr_cv(*args,X, y,trainfolds):
    """
    Function performs Grid search Cross validation for random forrests with trainfolds as folds generator. 
    Inputs:
    X: Train set
    y: Test set 
    trainfolds: CV folds generator
    Returns:
    best_params: Best parameters of the CV procedure
    grid_result: The output of the GridSearchCV method when fitted to
                 X and y
    """
    if trainfolds ==None:
        foldscv = StratifiedKFold(n_splits=5,random_state=11235)
        trainfolds =foldscv.split(X,wwfdf.Area_group.loc[X.index])
    # Perform Grid-Search
    gsc = GridSearchCV(
        estimator=RandomForestClassifier(),
        param_grid={
            'max_depth':(list(range(3,7))+[None]),
            'n_estimators': [100,300,500,1000],
            "min_samples_split":[2,3,4],
            "class_weight" : ["balanced"],
            "bootstrap": [False]
        },
        cv=trainfolds, scoring = ["accuracy"], verbose=1, 
        n_jobs=-1,refit = "accuracy",return_train_score = False)
    #  Grid result is the output of the gridsearchcv
    # best_params are the parameters of the highest scoring algorithm
    # coefficients are the weights of the fetures which signify which one is important
    grid_result = gsc.fit(X, y)
    best_params = grid_result.best_params_
    coefficients =grid_result.best_estimator_.feature_importances_
    

    return (best_params,grid_result,coefficients)

def som_cv(*args,X,y,trainfolds):
    if trainfolds ==None:
            foldscv = StratifiedKFold(n_splits=5,random_state=11235)
            trainfolds =foldscv.split(X,wwfdf.Area_group.loc[X.index])
        # Perform Grid-Search
    gsc = GridSearchCV(
        estimator=SKSOM(),
        param_grid={
            "x" : [8,10],
            'sigma':[1,2,0.5],
            'learning_rate': [0.1],
            "neighborhood_function":['gaussian','mexican_hat','bubble','triangle']
        },
        cv=trainfolds, scoring = ["accuracy"], verbose=1, 
        n_jobs=-1,refit = "accuracy",return_train_score = False)
    #  Grid result is the output of the gridsearchcv
    # best_params are the parameters of the highest scoring algorithm
    # coefficients are the weights of the fetures which signify which one is important
    grid_result = gsc.fit(X, y)
    best_params = grid_result.best_params_
    

    return (best_params,grid_result,[])
    


def knn_cv(*args,X, y,trainfolds):
    """
    Function performs Grid search Cross validation for random forrests with trainfolds as folds generator. 
    Inputs:
    X: Train set
    y: Test set 
    trainfolds: CV folds generator
    Returns:
    best_params: Best parameters of the CV procedure
    grid_result: The output of the GridSearchCV method when fitted to
                 X and y
    """
    print(args)
    try:
	    knnmetric = args[0]["metric"]
    except KeyError:
    	knnmetric = "minkowski"
    if trainfolds ==None:
        foldscv = StratifiedKFold(n_splits=5,random_state=11235)
        trainfolds =foldscv.split(X,wwfdf.Area_group.loc[X.index])
    # Perform Grid-Search
    gsc = GridSearchCV(
        estimator=KNeighborsClassifier(metric=knnmetric),
        param_grid={
        "n_neighbors": range(1,30),
       #,"braycurtis"],
            "weights":["uniform","distance"],
            "p": range(1,6)
        },
        cv=trainfolds, scoring = ["accuracy"], verbose=1, 
        n_jobs=-1,refit = "accuracy",return_train_score = False)
    #  Grid result is the output of the gridsearchcv
    # best_params are the parameters of the highest scoring algorithm
    # coefficients are the weights of the fetures which signify which one is important
    grid_result = gsc.fit(X, y)
    best_params = grid_result.best_params_
    
    

    return (best_params,grid_result,None)

def xgb_cv(X, y,trainfolds):
    """
    Function performs Grid search Cross validation for random forrests with trainfolds as folds generator. 
    Inputs:
    X: Train set
    y: Test set 
    trainfolds: CV folds generator
    Returns:
    best_params: Best parameters of the CV procedure
    grid_result: The output of the GridSearchCV method when fitted to
                 X and y
    """
    if trainfolds ==None:
        foldscv = StratifiedKFold(n_splits=5,random_state=11235)
        trainfolds =foldscv.split(X,wwfdf.Area_group.loc[X.index])
    # Perform Grid-Search
    gsc = GridSearchCV(
        estimator=xgb.XGBClassifier(objective="binary:logistic",learning_rate=0.2),
        param_grid={
            'max_depth': range(1,3),
            'n_estimators': [500,600],
            "min_child_weight":range(1,3)
            #"reg_alpha":[0,0.3,0.7,1],
            #"reg_lambda":[0,0.3,0.7,1]
            
        },
        cv=trainfolds, scoring = ["accuracy"], verbose=1, 
        n_jobs=-1,refit = "accuracy",return_train_score = False)
    #  Grid result is the output of the gridsearchcv
    # best_params are the parameters of the highest scoring algorithm
    # coefficients are the weights of the fetures which signify which one is important
    grid_result = gsc.fit(X, y)
    best_params = grid_result.best_params_
    coefficients =grid_result.best_estimator_.feature_importances_
    

    return (best_params,grid_result,coefficients) 
