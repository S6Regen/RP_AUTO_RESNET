# RP_AUTO_RESNET
Under Construction:
https://youtu.be/5w0Vzjf0b5M

A traditional neural network has in each layer many weighted sums operating off a single vector. That leaves you trying to find multiple worthwhile and different separating hyperplanes, perhaps not such an easy task. The biological brain does not have such a problem as there are far more nonlinarities involved and it is not structured into regualar repeating layers.   

An alternative is use (vector to vector) random projections to create multiple different windows on the single vector, resulting in an increase in dimension, then apply a nonlinear function to all the random projection elements.  Then provide each weighed sum with a different nonlinear window on the single vector.  A neuron then is: random projection, nonlinearity, weighed sum.

Using random projections also allows you more sensible control of the number of terms you can use in the weighted sum.
You can use more structured projections as an alternative to random projections.

If you use f(x)=a.x x>=0, f(x)=b.x x<0 as the nonlinear activation fuction then the system can set a=b=1 if it wants to allow automatic ResNet like information pathways to develop, rather than you forcing such pathways on the system. 
