//
//  CardArtRenderer.swift
//  SBPPersonalBanking
//
//  Dos funciones:
//   1) GENERAR el arte de la tarjeta y entregarlo en Base64 (para sembrar los
//      datos demo, simulando lo que HST mandaría en `cardImageBase64`).
//   2) DECODIFICAR un Base64 a imagen para mostrarla (app y extensión).
//

import UIKit

enum CardArtRenderer {

    // MARK: - Imagen para mostrar (con fallback)

    /// Devuelve la imagen de la tarjeta: usa el `cardImageBase64` si es una
    /// imagen válida y de tamaño razonable; si no (placeholder diminuto del mock,
    /// vacío o corrupto), genera el arte a partir de los campos de la tarjeta.
    static func image(for card: BankCard) -> UIImage {
        if let data = Data(base64Encoded: card.cardImageBase64),
           let image = UIImage(data: data),
           image.size.width >= 64 {           // ignora placeholders diminutos (p. ej. 1×1)
            return image
        }
        return render(for: card)
    }

    static func cgImage(for card: BankCard) -> CGImage? {
        image(for: card).cgImage
    }

    // MARK: - Decodificar (Base64 -> imagen)

    static func image(fromBase64 base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    static func cgImage(fromBase64 base64: String) -> CGImage? {
        image(fromBase64: base64)?.cgImage
    }

    // MARK: - Generar (tarjeta -> Base64 PNG)

    static func base64PNG(for card: BankCard) -> String {
        render(for: card).pngData()?.base64EncodedString() ?? ""
    }

    // MARK: - Dibujo

    private static func render(for card: BankCard,
                              size: CGSize = CGSize(width: 320, height: 202)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            path.addClip()

            // Fondo con degradado según la red de pago.
            let colors = gradientColors(for: card.paymentNetwork)
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors.map { $0.cgColor } as CFArray,
                                      locations: [0, 1])!
            cg.drawLinearGradient(gradient,
                                  start: CGPoint(x: 0, y: 0),
                                  end: CGPoint(x: size.width, y: size.height),
                                  options: [])

            // Chip simulado.
            let chip = CGRect(x: 28, y: 64, width: 46, height: 34)
            UIColor(white: 1, alpha: 0.85).setFill()
            UIBezierPath(roundedRect: chip, cornerRadius: 6).fill()

            let white = UIColor.white
            draw(text: "SBP", in: rect, at: CGPoint(x: 28, y: 22),
                 font: .systemFont(ofSize: 22, weight: .heavy), color: white)
            draw(text: card.paymentNetwork.uppercased(), in: rect,
                 at: CGPoint(x: size.width - 150, y: 26),
                 font: .systemFont(ofSize: 14, weight: .semibold),
                 color: white.withAlphaComponent(0.9), width: 122, align: .right)
            draw(text: card.maskedNumber, in: rect, at: CGPoint(x: 28, y: 116),
                 font: .monospacedSystemFont(ofSize: 20, weight: .medium), color: white)
            draw(text: card.cardHolderName.uppercased(), in: rect,
                 at: CGPoint(x: 28, y: 160),
                 font: .systemFont(ofSize: 13, weight: .semibold),
                 color: white.withAlphaComponent(0.9))
        }
    }

    private static func gradientColors(for paymentNetwork: String) -> [UIColor] {
        switch paymentNetwork.lowercased().replacingOccurrences(of: " ", with: "") {
        case "visa":
            return [UIColor(red: 0.10, green: 0.20, blue: 0.55, alpha: 1),
                    UIColor(red: 0.20, green: 0.45, blue: 0.85, alpha: 1)]
        case "mastercard":
            return [UIColor(red: 0.45, green: 0.10, blue: 0.10, alpha: 1),
                    UIColor(red: 0.85, green: 0.35, blue: 0.20, alpha: 1)]
        case "amex", "americanexpress":
            return [UIColor(red: 0.05, green: 0.35, blue: 0.45, alpha: 1),
                    UIColor(red: 0.15, green: 0.60, blue: 0.70, alpha: 1)]
        default:
            return [UIColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1),
                    UIColor(red: 0.40, green: 0.40, blue: 0.48, alpha: 1)]
        }
    }

    private static func draw(text: String,
                             in rect: CGRect,
                             at origin: CGPoint,
                             font: UIFont,
                             color: UIColor,
                             width: CGFloat? = nil,
                             align: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = align
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let drawWidth = width ?? (rect.width - origin.x - 16)
        let bounds = CGRect(x: origin.x, y: origin.y, width: drawWidth, height: font.lineHeight + 4)
        (text as NSString).draw(in: bounds, withAttributes: attributes)
    }
}
