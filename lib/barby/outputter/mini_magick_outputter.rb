require 'barby/outputter'
require 'mini_magick'

module Barby


  #Renders images from barcodes using RMagick
  #
  #Registers the to_png, to_gif, to_jpg and to_image methods
  class MiniMagickOutputter < Outputter

    register :to_png, :to_gif, :to_jpg, :to_image

    attr_writer :height, :xdim, :ydim, :margin
    attr_accessor :file_path

    def initialize(*)
      super
      @height, @xdim, @ydim, @margin = nil
    end

    #Returns a string containing a PNG image
    def to_png(*a)
      to_blob('png', *a)
    end

    #Returns a string containint a GIF image
    def to_gif(*a)
      to_blob('gif', *a)
    end

    #Returns a string containing a JPEG image
    def to_jpg(*a)
      to_blob('jpg', *a)
    end

    def to_blob(format, *a)
      img = to_image(*a)
      blob = img.to_blob{|i| i.format = format }

      #Release the memory used by RMagick explicitly. Ruby's GC
      #isn't aware of it and can't clean it up automatically
      img.destroy! if img.respond_to?(:destroy!)

      blob
    end

    #Returns an instance of Magick::Image
    def to_image(opts={})
      MiniMagick::Tool::Convert.new do | canvas |
        canvas.size "#{full_width}x#{full_height}"
        x1 = margin
        y1 = margin

        if barcode.two_dimensional?
          encoding.each do |line|
            line.split(//).map{|c| c == '1' }.each do |bar|
              if bar
                x2 = x1+(xdim-1)
                y2 = y1+(ydim-1)
                # For single pixels use point
                if x1 == x2 && y1 == y2
                  # bars.point(x1,y1)
                  canvas.draw "point #{x1}, #{y1}"
                else
                  # bars.rectangle(x1, y1, x2, y2)
                  canvas.draw "rectangle #{x1}, #{y1}, #{x2}, #{y2}"
                end
              end
              x1 += xdim
            end
            x1 = margin
            y1 += ydim
          end
        else
          booleans.each do |bar|
            if bar
              x2 = x1+(xdim-1)
              y2 = y1+(height-1)
              # bars.rectangle(x1, y1, x2, y2)
              canvas.draw "rectangle #{x1}, #{y1} #{x2}, #{y2}"
            end
            x1 += xdim
          end
        end

        canvas.xc "white"
        canvas.format "png"
        canvas << file_path
      end
    end


    #The height of the barcode in px
    #For 2D barcodes this is the number of "lines" * ydim
    def height
      barcode.two_dimensional? ? (ydim * encoding.length) : (@height || 100)
    end

    #The width of the barcode in px
    def width
      length * xdim
    end

    #Number of modules (xdims) on the x axis
    def length
      barcode.two_dimensional? ? encoding.first.length : encoding.length
    end

    #X dimension. 1X == 1px
    def xdim
      @xdim || 1
    end

    #Y dimension. Only for 2D codes
    def ydim
      @ydim || xdim
    end

    #The margin of each edge surrounding the barcode in pixels
    def margin
      @margin || 10
    end

    #The full width of the image. This is the width of the
    #barcode + the left and right margin
    def full_width
      width + (margin * 2)
    end

    #The height of the image. This is the height of the
    #barcode + the top and bottom margin
    def full_height
      height + (margin * 2)
    end


  end


end