// welcome_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  /// A convenience method for creating a [WelcomePage] widget.
  ///
  /// This is intended to be used as a root widget in a Flutter application.
  static Widget create() {
    return const WelcomePage();
  }

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1Animation;
  late Animation<Color?> _color2Animation;

  final Random _random = Random();

  // Function to generate a random color
  Color _randomColor() {
    return Color.fromRGBO(
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
      1,
    );
  }

  /// Initializes the animation controller and sets the first gradient
  /// animation.
  ///
  /// This method is called when the widget is inserted into the tree.
  ///
  /// The animation controller is set to repeat the animation forward and
  /// backward.
  /// The `_setNewGradientAnimation` function is called to set the first
  /// gradient animation.
  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _setNewGradientAnimation();

    // Loop the animation forward and backward
    _controller.repeat(reverse: true);
  }

  /// Sets a new gradient animation when the current animation is completed or
  /// dismissed.
  //
  /// This function generates two new random colors for the gradient and sets
  /// them as the start and end colors for the animation using [ColorTween].
  ///
  /// The animation controller is set to listen for every tick and updates the
  /// animation when the current animation is completed or dismissed.
  /// This ensures that the animation loops indefinitely.
  void _setNewGradientAnimation() {
    _color1Animation = ColorTween(
      begin: _randomColor(),
      end: _randomColor(),
    ).animate(_controller);

    _color2Animation = ColorTween(
      begin: _randomColor(),
      end: _randomColor(),
    ).animate(_controller);

    // Update animation on every tick
    _controller.addListener(() {
      if (_controller.status == AnimationStatus.completed ||
          _controller.status == AnimationStatus.dismissed) {
        setState(_setNewGradientAnimation);
      }
    });
  }

  /// Disposes the animation controller to free up resources.
  ///
  /// This method is called when the widget is removed from the widget tree.
  /// It ensures that the animation controller is properly disposed to prevent
  /// memory leaks.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds the welcome page.
  ///
  /// This page displays a gradient animation with a placeholder image and
  /// buttons to navigate to the login and register pages.
  ///
  /// The gradient animation is generated using [_setNewGradientAnimation] and
  /// the animation controller is updated on every tick.
  ///
  /// The buttons are elevated buttons with a rounded rectangle shape and a
  /// white text color. The login button has a deep purple color and the
  /// register button has a white background with a deep purple border.
  ///
  /// The page is wrapped in a [Scaffold] widget with a [SafeArea] widget as
  /// its body. This ensures that the content of the page is not obscured by
  /// the system bars.
  ///
  /// The page is designed to be responsive and works well on different screen
  /// sizes. The text and buttons are centered horizontally and the image is
  /// placed at the top of the page. The buttons are placed at the bottom of
  /// the page with a gap of 36 pixels between them.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _color1Animation.value ?? Colors.white,
                  _color2Animation.value ?? Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder for image or graphic
                  Container(
                    height: 150,
                    width: 150,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.insert_emoticon,
                      size: 80,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Welcome Text
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please login or register to continue',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Login Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple, // Button color
                          foregroundColor: Colors.white, // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 24,
                          ),
                        ),
                        onPressed: () => context.pushNamed('login'),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Register Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 24,
                          ),
                        ),
                        onPressed: () => context.pushNamed('register'),
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
