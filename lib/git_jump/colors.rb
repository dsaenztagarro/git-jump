# frozen_string_literal: true

module GitJump
  # Lightweight color module using ANSI escape codes
  # Inspired by dotsync's approach - no external dependencies
  module Colors
    # ANSI color codes (256-color palette)
    # Use \e[38;5;NNNm for foreground colors
    # Use \e[1m for bold
    # Use \e[0m to reset

    GREEN = 34
    RED = 196
    YELLOW = 220
    BLUE = 39
    CYAN = 51
    DIM = 242

    module_function

    def colorize(text, color:, bold: false)
      codes = []
      codes << "\e[38;5;#{color}m" if color
      codes << "\e[1m" if bold
      "#{codes.join}#{text}\e[0m"
    end

    def green(text, bold: false)
      colorize(text, color: GREEN, bold: bold)
    end

    def red(text, bold: false)
      colorize(text, color: RED, bold: bold)
    end

    def yellow(text, bold: false)
      colorize(text, color: YELLOW, bold: bold)
    end

    def blue(text, bold: false)
      colorize(text, color: BLUE, bold: bold)
    end

    def cyan(text, bold: false)
      colorize(text, color: CYAN, bold: bold)
    end

    def dim(text)
      colorize(text, color: DIM, bold: false)
    end

    def bold(text)
      "\e[1m#{text}\e[0m"
    end
  end
end
