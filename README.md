# nonlinear-ARX
This repository contains the implementation of a Nonlinear AutoRegressive with eXogenous inputs model. The project focuses on identifying and simulating the dynamics of a complex system using experimental data and polynomial regression.

Project Objectives
Building a NARX structure to capture nonlinear system dynamics that a simple linear ARX model cannot represent.
Using the Least Squares Method to determine optimal parameters.
Evaluating model performance through both one-step-ahead prediction and long-term simulation on separate validation datasets.

Technical Methodology
While a linear ARX model uses a simple sum of past inputs and outputs, this NARX model uses a polynomial of degree 'm', significantly increasing the number of parameters to better fit the data. 
The project includes a comparison with the standard MATLAB nlarx toolbox to verify the accuracy of the custom implementation.

How to Use
- Load the experimental datasets into MATLAB.
- Run the main script to perform the automated search for na, nb, and m.
- The script will generate plots for Prediction and Simulation.
