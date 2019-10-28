import numpy as np
from  minisom import MiniSom

class SKSOM():
    def __init__(self, sigma = 1,x=8,y=8,learning_rate = 0.5,neighborhood_function="triangle",iterations=5000):
        self.sigma = sigma
        self.x = x
        self.y = y
        self.learning_rate = learning_rate
        self.neighborhood_function = neighborhood_function
        self.iterations = iterations
#     def combine(self, inputs):
#         return sum([i*w for (i,w) in zip([1] + inputs, self.weights)])

    def predict(self, X):
        try:
            X = X.to_numpy()
        except AttributeError:
            pass
        predictions = self.classify(X)
        return np.array(predictions)

    def classify(self, data):
        """Classifies each sample in data in one of the classes definited
        using the method labels_map.
        Returns a list of the same length of data where the i-th element
        is the class assigned to data[i].
        """
        winmap = self.class_labels
        # because labels are in a dictionary and in a counter object
        # we have to take the most common class using this way
        default_class = np.sum(list(winmap.values())).most_common()[0][0]
        result = []
        for d in data:
            #Computes the coordinates of the winning neuron for the sample x
            win_position = self.som.winner(d)
            if win_position in winmap:
                result.append(winmap[win_position].most_common()[0][0])
            else:
                result.append(default_class)
        return result

    def fit(self, X, y, **kwargs):
        try:
            X = X.to_numpy()
            y = y.to_numpy()
        except AttributeError:
            pass
        self.__dict__.update(kwargs)
        self.som = MiniSom(self.x,self.x, X.shape[1], sigma=self.sigma, learning_rate=self.learning_rate, 
              neighborhood_function=self.neighborhood_function, random_seed=10)
        self.som.pca_weights_init(X)
        self.som.train_random(X, self.iterations, verbose=False)
        self.class_labels = self.som.labels_map(X, y)
        return(self)
        
    def set_params(self,**kwargs):
        self.__dict__.update(kwargs)
        return self
    def get_params(self, deep = False):
        som_params_keys = ["sigma","x","y","learning_rate","neighborhood_function"]
        dict_of_keys = { key: self.__dict__[key] for key in som_params_keys }
        return dict_of_keys