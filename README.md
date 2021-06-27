## Read ProjectReport.pdf

## Abstract
Heterogeneous team formation is still a challenging NP-Hard problem, despite the extensive
research performed on the topic. A suggested way of solving team formation problems are the
stochastic optimisation methods based on the concept of swarm intelligence. Such a method
is Particle Swarm Optimisation, proposed in 1995, it presents a promising and efficient way of
optimising different functions. The current project presents a novel approach for solving the
team formation problem using a specially modified version of the binary PSO algorithm. The
new algorithm is highly customisable, provides mechanics of fine-tuning its behaviour and the
focuses on balancing between exploration and exploitation during its execution. It relies on
a custom adaptation of the prime PSO components while keeping their meaning and original
mechanics. It uses dynamic inertia, changing topology and variable survivability principle
inspired by the selectivity concept in Genetic Algorithms. The result is a proposed solution for
a specific team formation problem, where a large set of university students have to be assigned
to small teams for a very important project. The algorithm is also focused on scalability and
provides the users with the full freedom of furtherly optimising it and adapting it to other
similar problems.

## Installation
The can be installed by running:

     gem install MBPSO_Team_Formation

Or it can be installed by running:

    gem install --local MBPSO_Team_Formation-1.0.3.gem
 
 ## Building the gem from the files
 
 Navigate to the current directory and run:
     
     gem build MBPSO_Team_Formation