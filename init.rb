require 'gosu'
require 'opengl'
require 'glu'

OpenGL.load_lib
GLU.load_lib

include OpenGL, GLU

class Dialog
    @@tile_width = 16
    @@tile_height = 8
    @@tiles = Gosu::Image.load_tiles('./gfx/dialog.png', @@tile_width, @@tile_height,  retro: true)
    @@font_size = 12
    @@font_face = './gfx/Retro Gaming.ttf'
    @@font = Gosu::Font.new(@@font_size, name: @@font_face)
    @@text_image = nil
    @@max_text_width = 200

    def self.draw_text(window, text, target_x, target_y)
        x = target_x
        y = target_y
        z = 0

        width = (@@font.text_width(text) / @@tile_width.to_f).ceil * @@tile_width
        width = @@max_text_width if width > @@max_text_width

        if @@text_image.nil?
            @@text_image = Gosu::Image.from_text(text, @@font_size, {
                font: @@font_face,
                width: width,
                align: :justify,
                retro: true
            })
        end

        height = (@@text_image.height / @@tile_height.to_f).ceil * @@tile_height

        tiles_in_width = (width / @@tile_width.to_f).ceil
        tiles_in_height = (height / @@tile_height.to_f).ceil

        arrow_x = x + @@tile_width
        arrow_y = y + height + 2 * @@tile_height - 1

        # top-left corner
        @@tiles[0].draw(x, y, z)

        # top-right corner
        @@tiles[2].draw(x + @@tile_width + width, y, z)

        # bottom-left corner
        @@tiles[8].draw(x, y + height + @@tile_height, z) 

        # bottom-right corner
        @@tiles[10].draw(x + @@tile_width + width, y + height + @@tile_height, z) 

        # top border
        tiles_in_width.times do |border_x|
            @@tiles[1].draw(x + (1 + border_x) * @@tile_width, y, z)
        end

        # bottom border
        tiles_in_width.times do |border_x|
            @@tiles[9].draw(x + (1 + border_x) * @@tile_width, y + @@tile_height + height, z)
        end

        # left border
        tiles_in_height.times do |border_y|
            @@tiles[4].draw(x, y + (1 + border_y) * @@tile_height, z)
        end

        # right border
        tiles_in_height.times do |border_y|
            @@tiles[6].draw(x + @@tile_width + width, y + (1 + border_y) * @@tile_height, z)
        end

        # main fill
        tiles_in_width.times do |tile_x|
            tiles_in_height.times do |tile_y|
                @@tiles[5].draw(x + (1 + tile_x) * @@tile_width, y + (1 + tile_y) * @@tile_height, z)
            end
        end

        # arrow
        @@tiles[11].draw(arrow_x, arrow_y, z)

        # text drawing
        @@text_image.draw(x + @@tile_width, y + @@tile_height, z, 1, 1, Gosu::Color::BLACK)
    end
end

class Window < Gosu::Window
    def initialize
        super(640, 480, false)

        @chara_x, @chara_y, @chara_z = 0, 0, 0
    end

    def button_down(id)
        super
        close! if id == Gosu::KB_ESCAPE
    end

    def needs_cursor?; true; end

    def update
        @chara_x += 1 if Gosu::button_down?(Gosu::KB_RIGHT)
        @chara_x -= 1 if Gosu::button_down?(Gosu::KB_LEFT)
        @chara_z -= 1 if Gosu::button_down?(Gosu::KB_UP)
        @chara_z += 1 if Gosu::button_down?(Gosu::KB_DOWN)
    end
    
    def draw
        gl do
            glEnable(GL_TEXTURE_2D)
            glEnable(GL_DEPTH_TEST)
        
            glMatrixMode(GL_PROJECTION)
            glLoadIdentity
            gluPerspective(45, self.width.to_f / self.height, 1, 1000)
        
            glMatrixMode(GL_MODELVIEW)
            glLoadIdentity
            gluLookAt(0, 100, 100,  0, 0, 0,  0, 1, 0)
            projection = ([0.0]*16).pack('F*')
            glGetDoublev(GL_PROJECTION_MATRIX, projection)
            model_view = ([0.0]*16).pack('F*')
            glGetDoublev(GL_MODELVIEW_MATRIX, model_view)
            viewport = ([0] * 4).pack('L*')
            glGetIntegerv(GL_VIEWPORT, viewport)
            pos_x, pos_y, pos_z = [0.0].pack('F'), [0.0].pack('F'), [0.0].pack('F')
            
            gluProject(@chara_x, @chara_y, @chara_z, model_view, projection, viewport, pos_x, pos_y, pos_z)
            self.caption = [pos_x.unpack('F')[0].floor, pos_y.unpack('F')[0].floor, pos_z.unpack('F')[0].floor]
            

            @chara ||= Gosu::Image.new('./temp.png', retro: true)
            glBindTexture(GL_TEXTURE_2D, @chara.gl_tex_info.tex_name)
            l, r, t, b = @chara.gl_tex_info.left, @chara.gl_tex_info.right, @chara.gl_tex_info.top, @chara.gl_tex_info.bottom

            glPushMatrix
            glTranslatef(@chara_x, @chara_y, @chara_z)
            glScalef(@chara.width, @chara.height, 1)
            glBegin(GL_QUADS)
                glTexCoord2d(l, t); glVertex3f(-0.5, 1, 0)
                glTexCoord2d(l, b); glVertex3f(-0.5, 0, 0)
                glTexCoord2d(r, b); glVertex3f(0.5, 0, 0)
                glTexCoord2d(r, t); glVertex3f(0.5, 1, 0)
            glEnd
            glPopMatrix
        end
        scale(2, 2) do
            Dialog.draw_text(self, 'Petite amélioration de la flèche, qu\'il va encore falloir placer en fonction de la cible du dialogue', 10, 10)
        end
    end
end

Window.new.show