import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ruang_nada/api_service.dart';
import 'package:ruang_nada/theme.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isConnected = true;

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: AppTheme.durationSlow,
    );
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    final String userMsg = _controller.text;
    final now = TimeOfDay.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    setState(() {
      _messages.add({"text": userMsg, "isUser": true, "time": timeStr});
      _isTyping = true;
      _isConnected = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final String botRes = await ApiService().askChatbot(userMsg);
      if (!mounted) return;
      final nowBot = TimeOfDay.now();
      final botTimeStr =
          "${nowBot.hour.toString().padLeft(2, '0')}:${nowBot.minute.toString().padLeft(2, '0')}";
      setState(() {
        _messages
            .add({"text": botRes, "isUser": false, "time": botTimeStr});
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final nowErr = TimeOfDay.now();
      final errTimeStr =
          "${nowErr.hour.toString().padLeft(2, '0')}:${nowErr.minute.toString().padLeft(2, '0')}";
      setState(() {
        _messages.add({
          "text": "Gagal terhubung ke chatbot. Silakan cek koneksi server.",
          "isUser": false,
          "isError": true,
          "time": errTimeStr,
        });
        _isTyping = false;
        _isConnected = false;
      });
      _scrollToBottom();
    }
  }

  void _resetChat() {
    ApiService().resetSession();
    setState(() {
      _messages.clear();
      _isConnected = true;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!_isConnected) _buildConnectionBanner(),
          Expanded(child: _buildMessageList()),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primary,
      foregroundColor: AppTheme.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: FadeTransition(
        opacity: _headerFade,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Asisten Ruang Nada",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Online",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: Colors.white70, size: 18),
          ),
          onPressed: _resetChat,
          tooltip: "Reset percakapan",
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildConnectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: AppTheme.error.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppTheme.error, size: 14),
          const SizedBox(width: 8),
          Text(
            "Koneksi ke chatbot terputus. Coba lagi nanti.",
            style: GoogleFonts.inter(
              color: AppTheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _ChatBubble(
        message: _messages[i],
        isLast: i == _messages.length - 1,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00897B).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              "Halo! 👋",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Saya asisten Ruang Nada.\nTanyakan apapun tentang alat musik!",
              textAlign: TextAlign.center,
              style: AppTheme.bodySm,
            ),
            const SizedBox(height: 32),
            ...["Apa itu Ruang Nada?", "Alat musik apa saja yang tersedia?", "Bagaimana cara menambahkan alat musik?"]
                .asMap()
                .entries
                .map((entry) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 500 + entry.key * 150),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - v)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _QuickPrompt(
                    text: entry.value,
                    onTap: () {
                      _controller.text = entry.value;
                      _sendMessage();
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotPulse(delay: 0),
                const SizedBox(width: 4),
                _DotPulse(delay: 150),
                const SizedBox(width: 4),
                _DotPulse(delay: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.sand, width: 1.5),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w400),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Tulis pesan...",
                  hintStyle: GoogleFonts.inter(
                      color: AppTheme.textLight, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) =>
                    _isTyping ? null : _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: AppTheme.durationFast,
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: _isTyping ? null : AppTheme.buttonGradient,
              color: _isTyping
                  ? AppTheme.textLight.withValues(alpha: 0.3)
                  : null,
              borderRadius: BorderRadius.circular(15),
              boxShadow: _isTyping ? [] : AppTheme.buttonShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isTyping ? null : _sendMessage,
                borderRadius: BorderRadius.circular(15),
                child: Center(
                  child: _isTyping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHAT BUBBLE
// ─────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isLast;

  const _ChatBubble({required this.message, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message['isUser'] == true;
    final bool isError = message['isError'] == true;
    final String text = message['text'] ?? '';
    final String time = message['time'] ?? '';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(isUser ? 20 * (1 - v) : -20 * (1 - v), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: isError
                          ? const LinearGradient(
                              colors: [AppTheme.error, AppTheme.error])
                          : AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isError
                          ? Icons.error_outline
                          : Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppTheme.primary
                          : isError
                              ? AppTheme.error.withValues(alpha: 0.08)
                              : AppTheme.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                            isUser ? AppTheme.radiusM : 4),
                        topRight:
                            const Radius.circular(AppTheme.radiusM),
                        bottomLeft:
                            const Radius.circular(AppTheme.radiusM),
                        bottomRight: Radius.circular(
                            isUser ? 4 : AppTheme.radiusM),
                      ),
                      boxShadow: isUser
                          ? [
                              BoxShadow(
                                color: AppTheme.primary
                                    .withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : AppTheme.cardShadow,
                      border: isError
                          ? Border.all(
                              color:
                                  AppTheme.error.withValues(alpha: 0.2),
                              width: 1)
                          : null,
                    ),
                    child: Text(
                      text,
                      style: GoogleFonts.inter(
                        color: isUser
                            ? AppTheme.white
                            : isError
                                ? AppTheme.error
                                : AppTheme.textDark,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (time.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: isUser ? 0 : 36,
                  right: isUser ? 4 : 0,
                ),
                child: Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DOT PULSE
// ─────────────────────────────────────────────
class _DotPulse extends StatefulWidget {
  final int delay;
  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppTheme.durationSlow,
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryLight,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QUICK PROMPT
// ─────────────────────────────────────────────
class _QuickPrompt extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickPrompt({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.sand, width: 1.5),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded,
                    size: 14, color: AppTheme.primaryLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }
}