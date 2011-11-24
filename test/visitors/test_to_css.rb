require 'helper'

module CSSPool
  module Visitors
    class TestToCSS < CSSPool::TestCase
      def assert_idempotent doc_or_source
        doc = if doc_or_source.is_a? CSSPool::CSS::Document
          doc_or_source
        else
          CSSPool.CSS doc_or_source.to_s
        end
        yield doc
        yield CSSPool.CSS doc.to_css

        doc_or_source
      end

      def test_font_serialization
        doc = CSSPool.CSS 'p { font: 14px/30px Tahoma; }'

        assert_idempotent doc do |doc|
          assert_equal 3, doc.rule_sets.first.declarations[0].expressions.length
        end

        assert_equal 'font: 14px / 30px Tahoma;',
          doc.rule_sets.first.declarations.first.to_css.strip
      end

      # FIXME: this is a bug in libcroco
      #def test_ident_followed_by_id
      #  doc = CSSPool.CSS 'p#div { font: foo, #666; }'
      #  assert_equal 'p#div', doc.rule_sets.first.selectors.first.to_css

      #  p doc.rule_sets.first.selectors

      #  doc = CSSPool.CSS 'p #div { font: foo, #666; }'

      #  p doc.rule_sets.first.selectors
      #  assert_equal 'p #div', doc.rule_sets.first.selectors.first.to_css
      #end

      def test_hash_operator
        assert_idempotent 'p { font: foo, #666; }' do |doc|
          assert_equal 2, doc.rule_sets.first.declarations[0].expressions.length
        end
      end

      def test_uri_operator
        assert_idempotent 'p { font: foo, url(http://example.com/); }' do |doc|
          assert_equal 2, doc.rule_sets.first.declarations[0].expressions.length
        end
      end

      def test_string_operator
        assert_idempotent 'p { font: foo, "foo"; }' do |doc|
          assert_equal 2, doc.rule_sets.first.declarations[0].expressions.length
        end
      end

      def test_function_operator
        assert_idempotent 'p { font: foo, foo(1); }' do |doc|
          assert_equal 2, doc.rule_sets.first.declarations[0].expressions.length
        end
      end

      def test_rgb_operator
        assert_idempotent 'p { font: foo, rgb(1,2,3); }' do |doc|
          assert_equal 2, doc.rule_sets.first.declarations[0].expressions.length
        end
      end

      def test_includes
        source = <<-eocss
          div[bar ~= 'adsf'] { background: red, blue; }
        eocss

        assert_idempotent source do |doc|
          assert_equal 1, doc.rule_sets.first.selectors.first.simple_selectors.first.additional_selectors.length
          assert_equal 2, doc.rule_sets.first.declarations[0].expressions.length
        end
      end

      def test_dashmatch
        source = <<-eocss
          div[bar |= 'adsf'] { background: red, blue; }
        eocss

        assert_idempotent source do |doc|
          assert_equal 1, doc.rule_sets.first.selectors.first.simple_selectors.first.additional_selectors.length
        end
      end

      def test_media
        source = <<-eocss
          @media print {
            div { background: red, blue; }
          }
        eocss
        assert_idempotent source do |doc|
          assert_equal 1, doc.rule_sets.first.media.length
        end
      end

      def test_multiple_media
        source = <<-eocss
          @media print, screen {
            div { background: red, blue; }
          }

          @media all {
            div { background: red, blue; }
          }
        eocss
        assert_idempotent source do |doc|
          assert_equal 2, doc.rule_sets.first.media.length
          assert_equal 1, doc.rule_sets[1].media.length
        end
      end

      def test_import
        source = <<-eocss
          @import "test.css";
          @import url("test.css");
          @import url("test.css") print, screen;
        eocss

        assert_idempotent source do |doc|
          assert_equal 3, doc.import_rules.length
          assert_equal 2, doc.import_rules.last.media.length
        end
      end

      def test_charsets
        source = <<-eocss
          @charset "UTF-8";
        eocss

        assert_idempotent source do |doc|
          assert_equal 1, doc.charsets.length
        end
      end
    end
  end
end
