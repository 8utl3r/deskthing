import turtle

# Create the turtle object
t = turtle.Turtle()

# Set the speed of the turtle
t.speed(0)

# Move the turtle to the starting position
t.penup()
t.goto(-100, 50)
t.pendown()

# Draw the face
t.fillcolor("yellow")
t.begin_fill()
for _ in range(2):
    t.forward(200)
    t.right(90)
    t.forward(100)
    t.right(90)
t.end_fill()

# Draw the eyes
t.penup()
t.goto(-60, 50)
t.pendown()
t.fillcolor("black")
t.begin_fill()
t.circle(20)
t.end_fill()

t.penup()
t.goto(40, 50)
t.pendown()
t.fillcolor("black")
t.begin_fill()
t.circle(20)
t.end_fill()

# Draw the mouth
t.penup()
t.goto(-30, -10)
t.pendown()
t.setheading(-60)
t.circle(40, 120)

# Hide the turtle
t.hideturtle()

# Keep the window open until it's closed manually
turtle.done()

