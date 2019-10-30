import numpy as np
from sklearn.base import TransformerMixin
from rpy2.robjects.packages import importr
import rpy2.robjects.numpy2ri

rpy2.robjects.numpy2ri.activate()

msq =importr("metagenomeSeq")
class CSSNormaliser(TransformerMixin):
    def __init__(self,log=False):
        """
        log: boolean
            whether to apply a log transfosmation to the data
            after normalisation
        """
        self.log = log
        pass

    def fit(self, X, y=None):
        MRTrain =msq.newMRexperiment(X.T)
        self.p = msq.cumNormStat(MRTrain)
        return(self)
    def transform(self, X):
        MRTest = msq.newMRexperiment(X.T)
        Normalisation =msq.cumNorm(MRTest, p = self.p)
        Rmatrix=msq.MRcounts(Normalisation,norm = True,log = self.log)
        # converting r matrix to python
        Normalised_numpy = np.array(Rmatrix).T
        return(Normalised_numpy)
