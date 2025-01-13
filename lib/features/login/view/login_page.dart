// login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ta_client/features/login/bloc/login_bloc.dart';
import 'package:ta_client/features/login/bloc/login_event.dart';
import 'package:ta_client/features/login/bloc/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static Widget create() {
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: const LoginPage(),
    );
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true; // Initial state of password visibility
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xffFBFDFF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        title: const Text(
          'Masuk',
          style: TextStyle(
            fontVariations: [
              FontVariation('wght', 800),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.pushReplacementNamed(context, Routes.dashboard);
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(
                    fontVariations: [
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  prefixIcon: Opacity(
                    opacity: 0.3,
                    child: Icon(Icons.person),
                  ),
                  hintText: 'Email or Username',
                ),
                onChanged: (value) =>
                    context.read<LoginBloc>().add(LoginEmailChanged(value)),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kata Sandi',
                  style: TextStyle(
                    fontVariations: [
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                obscureText: _obscureText,
                decoration: InputDecoration(
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey),
                  ),
                  prefixIcon: const Opacity(
                    opacity: 0.3,
                    child: Icon(Icons.lock),
                  ),
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: _obscureText ? Colors.grey : Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                onChanged: (value) =>
                    context.read<LoginBloc>().add(LoginPasswordChanged(value)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<LoginBloc>().add(LoginSubmitted());
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  const Text(
                    'Atau login dengan',
                    style: TextStyle(
                      fontVariations: [
                        FontVariation('wght', 500),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors
                        .transparent, // Transparent Material to use custom decoration
                    borderRadius:
                        BorderRadius.circular(64), // Match decoration corners
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(64), // Match decoration corners
                      onTap: () {
                        // Your onPressed logic here
                        print('Button clicked!');
                      },
                      onHover: (hovering) {
                        // Debug hover effect if needed
                        setState(() {
                          _isHovered = hovering;
                        });
                      },
                      hoverColor: Colors.grey[300], // Hover effect
                      splashColor: Colors.grey[400], // Splash effect
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 200), // Smooth transition
                        padding: const EdgeInsets.all(
                            16), // Adjust padding as needed
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? Colors.grey[300]
                              : Colors.white, // Dynamic background
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(2, 2),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                          borderRadius:
                              BorderRadius.circular(64), // Rounded corners
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/devicon_google.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  const Text(
                    'Belum Punya Akun?',
                    style: TextStyle(
                      fontVariations: [
                        FontVariation('wght', 500),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/register',
                      );
                    },
                    child: Text(
                      'Daftar disini',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontVariations: [
                          const FontVariation('wght', 800),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
