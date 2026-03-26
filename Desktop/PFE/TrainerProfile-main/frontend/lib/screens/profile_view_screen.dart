import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/formateur_model.dart';

class ProfileViewScreen extends StatelessWidget {
  final FormateurModel profile;

  const ProfileViewScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Formateur'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: profile.profilePicture.isNotEmpty
                        ? MemoryImage(base64Decode(profile.profilePicture))
                        : null,
                    child: profile.profilePicture.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${profile.firstName} ${profile.lastName}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.jobTitle.isNotEmpty
                        ? profile.jobTitle
                        : 'Formateur',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          profile.location.isNotEmpty
                              ? profile.location
                              : 'Non spécifié',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('À propos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(profile.bio.isNotEmpty
                      ? profile.bio
                      : 'Aucune description fournie.'),
                  const SizedBox(height: 24),
                  if (profile.expertise.isNotEmpty) ...[
                    const Text('Domaines d\'expertise',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: profile.expertise
                          .map((e) => Chip(
                                label: Text(e),
                                backgroundColor: Colors.blue.shade100,
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (profile.certifications.isNotEmpty) ...[
                    const Text('Certifications',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...profile.certifications.map((c) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.workspace_premium,
                              color: Colors.amber),
                          title: Text(c.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${c.issuer} · ${c.year}'),
                        )),
                    const SizedBox(height: 24),
                  ],
                  const Text('Contact & Liens',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 8,
                    leading: const Icon(Icons.email, color: Colors.blue),
                    title: Text(profile.email.isNotEmpty
                        ? profile.email
                        : 'Non spécifié'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 8,
                    leading: const Icon(Icons.phone, color: Colors.blue),
                    title: Text(profile.phone.isNotEmpty
                        ? profile.phone
                        : 'Non spécifié'),
                  ),
                  if (profile.linkedIn.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      horizontalTitleGap: 8,
                      leading: const Icon(Icons.link, color: Colors.blue),
                      title: Text(profile.linkedIn),
                    ),
                  if (profile.portfolio.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      horizontalTitleGap: 8,
                      leading: const Icon(Icons.language, color: Colors.blue),
                      title: Text(profile.portfolio),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
