import os

path = r"c:\Users\yotub\Desktop\PFE\skillspace_front\lib\features\recruiter\presentation\pages\recruiter_dashboard_page.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

target1 = """                  AnimatedReveal(
                    delay: const Duration(milliseconds: 100),
                    direction: RevealDirection.fromTop,
                    child: Text(
                      l10n.recruiterDashboard,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),"""

repl1 = """                  AnimatedReveal(
                    delay: const Duration(milliseconds: 100),
                    direction: RevealDirection.fromTop,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (data.logoUrl != null && data.logoUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data.logoUrl!,
                                height: 32,
                                width: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, __) => const Icon(Icons.business, size: 32, color: AppColors.textGray),
                              ),
                            ),
                          ),
                        Text(
                          '${l10n.welcome}, ${data.companyName}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),"""

target2 = """                  AnimatedReveal(
                    delay: const Duration(milliseconds: 200),
                    direction: RevealDirection.fromTop,
                    child: Row(
                      children: [
                        if (data.logoUrl != null && data.logoUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                data.logoUrl!,
                                height: 28,
                                width: 28,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, __) => const Icon(Icons.business, size: 24, color: AppColors.textGray),
                              ),
                            ),
                          ),
                        Text(
                          '${l10n.welcome}, ${data.companyName}',
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),"""

repl2 = """                  AnimatedReveal(
                    delay: const Duration(milliseconds: 200),
                    direction: RevealDirection.fromTop,
                    child: Text(
                      l10n.recruiterDashboard,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textGray,
                      ),
                    ),
                  ),"""

def normalize_crlf(s):
    return s.replace('\r\n', '\n')

text = normalize_crlf(text)
target1 = normalize_crlf(target1)
repl1 = normalize_crlf(repl1)
target2 = normalize_crlf(target2)
repl2 = normalize_crlf(repl2)

if target1 in text:
    text = text.replace(target1, repl1)
    print("Replaced target 1")
else:
    print("Target 1 not found")

if target2 in text:
    text = text.replace(target2, repl2)
    print("Replaced target 2")
else:
    print("Target 2 not found")

with open(path, "w", encoding="utf-8") as f:
    f.write(text)
print("Done!")
