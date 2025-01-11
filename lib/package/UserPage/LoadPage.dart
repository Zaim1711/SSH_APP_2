import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ssh_aplication/package/UserPage/LoginPage.dart';

class LoadPage extends StatefulWidget {
  @override
  _LoadPageState createState() => _LoadPageState();
}

class _LoadPageState extends State<LoadPage> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<Offset> _iconSlideAnimation;
  late Animation<double> _sshTextOpacity;
  late Animation<Offset> _sshTextSlideAnimation;
  late Animation<double> _descTextOpacity;
  late Animation<Offset> _descTextSlideAnimation;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Interval(0.0, 0.7, curve: Curves.easeInOutCubic),
    ));

    _iconScaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 30.0,
      ),
    ]).animate(_iconController);

    _iconSlideAnimation = Tween<Offset>(
      begin: Offset(0.75, 0),
      end: Offset(-0.25, 0),
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _sshTextOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Interval(0.3, 0.8, curve: Curves.easeIn),
    ));

    _sshTextSlideAnimation = Tween<Offset>(
      begin: Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _descTextOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Interval(0.6, 1.0, curve: Curves.easeIn),
    ));

    _descTextSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.elasticOut,
    ));

    _iconController.forward().then((_) {
      _textController.forward();
    });

    _navigateToLogin();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) =>
                FadeTransition(
              opacity: animation,
              child: LoginPage(),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D187E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 60, // Memberikan ruang untuk animasi
              child: AnimatedBuilder(
                animation: Listenable.merge([_iconController, _textController]),
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon dengan animasi
                      SlideTransition(
                        position: _iconSlideAnimation,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Transform.scale(
                            scale: _iconScaleAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Text SSH dengan animasi
                      FadeTransition(
                        opacity: _sshTextOpacity,
                        child: SlideTransition(
                          position: _sshTextSlideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 1),
                            child: Text(
                              'SSH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Text description dengan animasi
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _descTextOpacity,
                  child: SlideTransition(
                    position: _descTextSlideAnimation,
                    child: Text(
                      '(Stop Sexual Harassment)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
