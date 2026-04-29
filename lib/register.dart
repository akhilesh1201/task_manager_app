import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    return emailRegex.hasMatch(email);
  }

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    if (password.text != confirm.text) {
      showMessage("Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = ParseUser(
      email.text.trim(),
      password.text.trim(),
      email.text.trim(),
    );

    var response = await user.signUp();

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      showMessage("Registered Successfully");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            prefilledEmail: email.text.trim(),
          ),
        ),
      );
    } else {
      final errorMsg = response.error?.message ?? "Error";

      showMessage(response.error?.message ?? "Error");

      if (errorMsg.contains("Account already exists")) {
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(
                prefilledEmail: email.text.trim(),
              ),
            ),
          );
        });
      }
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Center(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUnfocus,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              SizedBox(
                width: 300,
                child: TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    helperText: "2024mt13042@wilp.bits-pilani.ac.in",
                    hintText: "2024mt13042@wilp.bits-pilani.ac.in",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!isValidEmail(value)) {
                      return "Enter valid email";
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: 15),

              SizedBox(
                width: 300,
                child: TextFormField(
                  controller: password,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Minimum 6 characters required";
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: 15),

              SizedBox(
                width: 300,
                child: TextFormField(
                  controller: confirm,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: "Re-enter Password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm password";
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(150, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child:  _isLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}