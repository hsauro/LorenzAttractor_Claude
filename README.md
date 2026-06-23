## Lorenz Attractor Simulator

To get some practice with using Claude Code, I created this simple Lorenz attractor simulator. It took less than 30 minutes to create the code.

Once setp up using Claude Code is very easy. I started with a basic FMX project with a form and some TLayout panel. The center control had a TSkPaintBox and I added some buttons. A created teh stubes for the OnDraw and button clicks 
although I am not sure how necessary that was. I then asked Claude to write the main code for setting up the differential equations, inlementing a simple Euler solver and creating the skia drawing code. 

After the first version was made we iterated by adding 3D support, added more UI controls, (Claude did this automatically by upding the fmx file). We also added zooom control and sliders to set the model parameters. 

2D example:

<img width="1530" height="1067" alt="image" src="https://github.com/user-attachments/assets/3f59c2aa-81dc-4518-922e-301edaaf7710" />

3D example:

<img width="1527" height="1061" alt="image" src="https://github.com/user-attachments/assets/ba10c17b-14c4-40ff-9f99-e96acd125fa1" />
