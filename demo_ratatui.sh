cargo new ratatui_demo
cd ratatui_demo
cargo add ratatui crossterm anyhow
cat >src/main.rs <<'RS'
use anyhow::Result;
use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use ratatui::{
    layout::{Constraint, Direction, Layout},
    style::{Modifier, Style},
    text::Line,
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph},
    DefaultTerminal, Frame,
};

struct App {
    items: Vec<String>,
    state: ListState,
    should_quit: bool,
}

impl App {
    fn new() -> Self {
        let items = (1..=300)
            .map(|i| format!("file_{i:03}.txt"))
            .collect::<Vec<_>>();

        let mut state = ListState::default();
        state.select(Some(0));

        Self {
            items,
            state,
            should_quit: false,
        }
    }

    fn run(&mut self, terminal: &mut DefaultTerminal) -> Result<()> {
        while !self.should_quit {
            terminal.draw(|frame| self.draw(frame))?;
            self.handle_event()?;
        }

        Ok(())
    }

    fn draw(&mut self, frame: &mut Frame) {
        let area = frame.area();

        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Min(1),
                Constraint::Length(1),
            ])
            .split(area);

        let list_items = self
            .items
            .iter()
            .enumerate()
            .map(|(index, item)| {
                ListItem::new(Line::from(format!(" {:03}  {}", index + 1, item)))
            })
            .collect::<Vec<_>>();

        let list = List::new(list_items)
            .block(
                Block::default()
                    .title(" Ratatui Scroll Demo ")
                    .borders(Borders::ALL),
            )
            .highlight_style(
                Style::default()
                    .add_modifier(Modifier::REVERSED),
            )
            .highlight_symbol(">> ");

        frame.render_stateful_widget(list, chunks[0], &mut self.state);

        let status = Paragraph::new(
            " ↑/↓ or j/k scroll | PgUp/PgDn page | g top | G bottom | q quit ",
        );

        frame.render_widget(status, chunks[1]);
    }

    fn handle_event(&mut self) -> Result<()> {
        if let Event::Key(key) = event::read()? {
            if key.kind == KeyEventKind::Press {
                match key.code {
                    KeyCode::Char('q') | KeyCode::Esc => self.quit(),

                    KeyCode::Down | KeyCode::Char('j') => self.next(),
                    KeyCode::Up | KeyCode::Char('k') => self.previous(),

                    KeyCode::PageDown => self.page_down(),
                    KeyCode::PageUp => self.page_up(),

                    KeyCode::Char('g') => self.first(),
                    KeyCode::Char('G') => self.last(),

                    _ => {}
                }
            }
        }

        Ok(())
    }

    fn selected(&self) -> usize {
        self.state.selected().unwrap_or(0)
    }

    fn select(&mut self, index: usize) {
        if self.items.is_empty() {
            self.state.select(None);
        } else {
            let index = index.min(self.items.len() - 1);
            self.state.select(Some(index));
        }
    }

    fn next(&mut self) {
        let index = self.selected();
        self.select(index.saturating_add(1));
    }

    fn previous(&mut self) {
        let index = self.selected();
        self.select(index.saturating_sub(1));
    }

    fn page_down(&mut self) {
        let index = self.selected();
        self.select(index.saturating_add(10));
    }

    fn page_up(&mut self) {
        let index = self.selected();
        self.select(index.saturating_sub(10));
    }

    fn first(&mut self) {
        self.select(0);
    }

    fn last(&mut self) {
        if !self.items.is_empty() {
            self.select(self.items.len() - 1);
        }
    }

    fn quit(&mut self) {
        self.should_quit = true;
    }
}

fn main() -> Result<()> {
    let mut terminal = ratatui::init();

    let result = App::new().run(&mut terminal);

    ratatui::restore();

    result
}
RS
cargo run
